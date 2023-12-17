#!/usr/bin/python3
"""
Simple python client.

Should be easier to work with and also demonstrate interop with the game
server.

"""
import sys
import argparse

import socket
import json
import gzip
from types import SimpleNamespace

import curses

from pprint import pprint

# Networking #

DEFAULT_HOST, DEFAULT_PORT = "127.0.0.1", 9999


class Request(dict):

    # game_id = str(uuid.uuid1())
    game_id = None
    compress = False
    minify = True

    @classmethod
    def make_rqst(cls, body):
        return cls(
            game_id=cls.game_id,
            compress=cls.compress,
            minify=cls.minify,
            type=body,
        )

    @classmethod
    def start(cls, config=None):
        data = config or {}
        return cls.make_rqst({"START": data})

    @classmethod
    def action(cls, action_type, data=None):
        d = {"GAME_CMD": {action_type: data}}
        return cls(
            game_id=cls.game_id,
            compress=cls.compress,
            minify=cls.minify,
            type=d,
        )

    # @classmethod
    # def prompt_response(cls, data):
    #     return cls(
    #         game_id=cls.game_id,
    #         type='PROMPT',
    #         data=data or {}
    #     )

    # @classmethod
    # def get(cls): pass  # stub

    # @classmethod
    # def set(cls, key, val=None):
    #     d = {'key': key, 'val': val}
    #     return cls(
    #         game_id=cls.game_id,
    #         type='SET',
    #         data=d
    #     )

    @classmethod
    def quit(cls):
        data = {}
        return cls.make_rqst({"QUIT": data})


class Response(SimpleNamespace):

    def __init__(self, *args, **kwargs):
        state = (
            kwargs.get('payload', {})
            .get('CMD_RESULT', {})
            .pop('state', None)
        )
        events = (
            kwargs.get('payload', {})
            .get('CMD_RESULT', {})
            .pop('events', None)
        )
        self.gs = SimpleNamespace(**state) if state else None
        self.events = events
        super().__init__(*args, **kwargs)


class TCPClient:

    def __init__(self, host, port):
        self.host, self.port = host, port
        self.response = None

    def send(self, request):
        request_data = json.dumps(request)

        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
            sock.connect((self.host, self.port))
            print(bytes(request_data, 'utf-8'), file=sys.stderr)
            sock.sendall(bytes(request_data, 'utf-8'))

            received = b''
            while True:
                chunk = sock.recv(1024)
                received += chunk
                if not chunk:
                    break

            print("received: %d bytes" % len(received), file=sys.stderr)
            if Request.compress:
                received = gzip.decompress(received)

            rdata = json.loads(str(received, 'utf-8'))
            self.response = Response(**rdata)

        return self.response

    def close(self):
        pass
        # self.sock.close()


# curses client #


PLAYER_COLOR_PAIR = 1
MONSTER_COLOR_PAIR = 2


def curses_init(screen):
    curses.curs_set(0)  # Hide cursor

    curses.init_pair(
        PLAYER_COLOR_PAIR, curses.COLOR_YELLOW, curses.COLOR_BLACK)
    curses.init_pair(
        MONSTER_COLOR_PAIR, curses.COLOR_GREEN, curses.COLOR_BLACK)


def curses_shutdown(screen):
    curses.curs_set(1)


def draw_map(screen, gs):
    for i, cell in enumerate(gs.map):
        ch = '#' if cell == 'WALL' else ' '
        x = i % 80  # TODO: unhardcode this
        y = i // 80
        # curses.beep()
        screen.addch(y, x, ch)


def draw_entities(screen, gs):

    for e in gs.actors:
        pos = e['components']['POSITION']
        vis = e['components']['VISIBLE']

        if 'PLAYER' in e['components']:
            color = curses.color_pair(PLAYER_COLOR_PAIR) | curses.A_BOLD
        else:
            color = curses.color_pair(MONSTER_COLOR_PAIR | curses.A_BOLD)

        screen.addch(pos['y'], pos['x'], vis['glyph'], color)


def draw_hud(screen, gs, events):

    info_panel_x = 82

    screen.addstr(0, info_panel_x, f"Ticks: {gs.ticks}")

    yoffset = 2
    for actor in gs.actors:
        vis = actor['components']['VISIBLE']
        hlth = actor['components']['HEALTH']
        screen.addstr(
            yoffset, info_panel_x,
            f"{chr(vis['glyph'])} - Hp: {hlth['hp']}/{hlth['max_hp']}")
        yoffset += 1

    yoffset += 1
    for ev in events:
        if m := ev['msg']:
            screen.addstr(yoffset, info_panel_x, m)
            yoffset += 1


def curses_draw(screen, gs, events):
    # screen.refresh()
    screen.clear()
    draw_map(screen, gs)
    draw_entities(screen, gs)
    draw_hud(screen, gs, events)


def handle_input(screen):
    c = screen.getch()
    if c == ord('q'):
        return Request.make_rqst({"QUIT": {}})

    if c in (ord("h"), curses.KEY_LEFT):
        return Request.action("MOVE", {"x": -1, "y": 0})
    if c in (ord("j"), curses.KEY_DOWN):
        return Request.action("MOVE", {"x": 0, "y": 1})
    if c in (ord("k"), curses.KEY_UP):
        return Request.action("MOVE", {"x": 0, "y": -1})
    if c in (ord("l"), curses.KEY_RIGHT):
        return Request.action("MOVE", {"x": 1, "y": 0})


def curses_run(screen, server):

    curses_init(screen)

    resp = server.send(Request.start())
    if resp.status == "ERROR":
        print(resp, file=sys.stderr)
        return sys.exit("[SERVER ERROR] Game could not start")
    Request.game_id = resp.game_id

    while True:
        curses_draw(screen, resp.gs, resp.events)
        if rqst := handle_input(screen):
            resp = server.send(rqst)
            if 'QUIT' in rqst["type"]:
                break
            if resp.status == "ERROR":
                print(resp, file=sys.stderr)
            result = resp.payload.get('CMD_RESULT', {}).get('result')
            if result == 'GAME_OVER':
                # server.send(Request.make_rqst({'QUIT': {}}))
                screen.addstr(
                    21, 0, "You're dead :( Press R to restart, Q to quit.")
                while True:
                    key = screen.getch()
                    if key == ord('r'):
                        server.send(Request.quit())
                        Request.game_id = None
                        return curses_run(screen, server)
                    elif key == ord('q'):
                        server.send(Request.quit())
                        return

    curses_shutdown(screen)


def inspect_responses(server):

    while True:

        cmd = input("Input: ")

        if cmd in ("m", "minify"):
            Request.minify = not Request.minify
            print(f"Minify opt is {Request.minify}")
        if cmd in ("c", "compress"):
            Request.compress = not Request.compress
            print(f"Compress opt is {Request.compress}")

        if cmd in ("s", "start"):
            req = Request.start()
            resp = server.send(req)
            Request.game_id = resp.game_id
            pprint(resp)
        if cmd in ('me', 'move_east'):
            req = Request.action('MOVE', {'x': 1, 'y': 0})
            resp = server.send(req)
            pprint(resp)
        if cmd in ('mw', 'move_west'):
            req = Request.action('MOVE', {'x': -1, 'y': 0})
            resp = server.send(req)
            pprint(resp)
        if cmd in ('mn', 'move_north'):
            req = Request.action('MOVE', {'x': 0, 'y': -1})
            resp = server.send(req)
            pprint(resp)
        if cmd in ('ms', 'move_south'):
            req = Request.action('MOVE', {'x': 0, 'y': 1})
            resp = server.send(req)
            pprint(resp)

        # TODO: more request types
        if cmd in ("q", "quit"):
            req = Request.quit()
            resp = server.send(req)
            Request.game_id = None
            pprint(resp)


if __name__ == '__main__':

    parser = argparse.ArgumentParser(conflict_handler='resolve')
    parser.add_argument(
        '-h', '--host', default=DEFAULT_HOST, help='Server host')
    parser.add_argument(
        '-p', '--port', default=DEFAULT_PORT, help='Server port')
    parser.add_argument(
        '--playground', action='store_true', help='Send and inspect requests')

    args = parser.parse_args()
    host, port = args.host, args.port

    server = TCPClient(host, port)
    if args.playground:
        inspect_responses(server)
    else:
        curses.wrapper(curses_run, server)
