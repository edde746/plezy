#!/usr/bin/env python3

from __future__ import annotations

import ast
from pathlib import Path
import re
import unittest
from typing import Any


ROOT_DIR = Path(__file__).resolve().parents[2]


def _mapping_separator(value: str) -> int | None:
    quote: str | None = None
    escaped = False
    for index, character in enumerate(value):
        if escaped:
            escaped = False
            continue
        if character == "\\" and quote is not None:
            escaped = True
            continue
        if character in {'"', "'"}:
            if quote is None:
                quote = character
            elif quote == character:
                quote = None
            continue
        if character == ":" and quote is None and (
            index + 1 == len(value) or value[index + 1].isspace()
        ):
            return index
    return None


def _scalar(value: str) -> Any:
    if value.startswith(('"', "'")):
        return ast.literal_eval(value)
    if value == "true":
        return True
    if value == "false":
        return False
    if value in {"null", "~"}:
        return None
    if re.fullmatch(r"-?\d+", value):
        return int(value)
    return value


def _parse_node(lines: list[tuple[int, str]], index: int, indent: int) -> tuple[Any, int]:
    if lines[index][0] != indent:
        raise ValueError(f"unexpected indentation at line {index + 1}")
    if lines[index][1].startswith("-"):
        result: list[Any] = []
        while index < len(lines) and lines[index][0] == indent and lines[index][1].startswith("-"):
            item = lines[index][1][1:].lstrip()
            index += 1
            separator = _mapping_separator(item)
            if separator is None:
                result.append(_scalar(item))
                continue

            key = item[:separator]
            value = item[separator + 1 :].lstrip()
            if value:
                result.append({key: _scalar(value)})
            elif index < len(lines) and lines[index][0] > indent:
                child, index = _parse_node(lines, index, lines[index][0])
                result.append({key: child})
            else:
                result.append({key: None})
        return result, index

    result_map: dict[str, Any] = {}
    while index < len(lines) and lines[index][0] == indent and not lines[index][1].startswith("-"):
        item = lines[index][1]
        separator = _mapping_separator(item)
        if separator is None:
            raise ValueError(f"expected mapping at line {index + 1}")
        key = item[:separator]
        value = item[separator + 1 :].lstrip()
        index += 1
        if value:
            result_map[key] = _scalar(value)
        elif index < len(lines) and lines[index][0] > indent:
            result_map[key], index = _parse_node(lines, index, lines[index][0])
        else:
            result_map[key] = None
    return result_map, index


def load_flow(relative_path: str) -> list[dict[str, Any]]:
    contents = (ROOT_DIR / relative_path).read_text(encoding="utf-8")
    try:
        commands = contents.split("---", maxsplit=1)[1]
    except IndexError as error:
        raise ValueError(f"{relative_path} has no Maestro command document") from error
    lines = [
        (len(line) - len(line.lstrip(" ")), line.lstrip(" "))
        for line in commands.splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    ]
    parsed, next_index = _parse_node(lines, 0, 0)
    if next_index != len(lines) or not isinstance(parsed, list):
        raise ValueError(f"could not parse all commands in {relative_path}")
    return parsed


def command_name(step: dict[str, Any]) -> str:
    if len(step) != 1:
        raise ValueError(f"expected one command per step, got {step!r}")
    return next(iter(step))


def platform_pair(steps: list[dict[str, Any]], index: int) -> dict[str, list[dict[str, Any]]]:
    pair = steps[index : index + 2]
    if len(pair) != 2 or [command_name(step) for step in pair] != ["runFlow", "runFlow"]:
        raise AssertionError(f"expected adjacent platform runFlow pair at command {index}")
    branches = {step["runFlow"]["when"]["platform"]: step["runFlow"]["commands"] for step in pair}
    if set(branches) != {"iOS", "Android"}:
        raise AssertionError(f"expected iOS and Android branches, got {set(branches)}")
    return branches


class MaestroFlowContractTests(unittest.TestCase):
    def test_tv_result_selector_cannot_select_the_query_field(self) -> None:
        steps = load_flow(".maestro/regression_flows/05_tv_next_episode_back.yaml")
        observation = next(
            step["extendedWaitUntil"]
            for step in steps
            if command_name(step) == "extendedWaitUntil"
            and isinstance(step["extendedWaitUntil"], dict)
            and "TV show" in str(step["extendedWaitUntil"].get("visible", ""))
        )
        selector = observation["visible"]

        self.assertIsNotNone(re.fullmatch(selector, "Maestro Show, TV show, unwatched"))
        self.assertIsNotNone(re.fullmatch(selector, "Maestro Show, TV show, watched"))
        self.assertIsNone(re.fullmatch(selector, "Maestro Show"))
        self.assertIn({"tapOn": selector}, steps)

    def test_offline_fault_is_injected_after_movies_tab_content_is_observed(self) -> None:
        steps = load_flow(".maestro/flows/09_download_offline_playback.yaml")
        movies_index = next(
            index
            for index, step in enumerate(steps)
            if step.get("tapOn") == {"text": "Movies", "waitToSettleTimeoutMs": 3000}
        )
        observation_index = next(
            index
            for index, step in enumerate(steps[movies_index + 1 :], movies_index + 1)
            if step.get("extendedWaitUntil", {}).get("visible") == "(?s).*Alpha Archive.*"
        )
        offline_index = next(
            index
            for index, step in enumerate(steps)
            if step.get("runScript", {}).get("file") == "../scripts/set_jellyfin_offline.js"
        )

        self.assertLess(movies_index, observation_index)
        self.assertLess(observation_index, offline_index)
        self.assertEqual(steps[observation_index]["extendedWaitUntil"]["timeout"], 60000)

    def test_tv_prompt_dismissal_has_platform_specific_controls(self) -> None:
        steps = load_flow(".maestro/regression_flows/05_tv_next_episode_back.yaml")
        cancel_index = next(
            index
            for index, step in enumerate(steps)
            if step.get("extendedWaitUntil", {}).get("visible") == "(?s)^Cancel$"
        )
        branches = platform_pair(steps, cancel_index + 1)

        self.assertEqual(branches["iOS"], [{"tapOn": "Cancel"}])
        self.assertEqual(branches["Android"], [{"pressKey": "back"}])

    def test_offline_flow_back_and_close_controls_are_platform_specific(self) -> None:
        steps = load_flow(".maestro/flows/09_download_offline_playback.yaml")
        platform_pair_indices = [
            index
            for index in range(len(steps) - 1)
            if command_name(steps[index]) == "runFlow"
            and command_name(steps[index + 1]) == "runFlow"
            and steps[index]["runFlow"].get("when", {}).get("platform") == "iOS"
            and steps[index + 1]["runFlow"].get("when", {}).get("platform") == "Android"
        ]
        self.assertEqual(len(platform_pair_indices), 2)
        detail_close = platform_pair(steps, platform_pair_indices[0])
        player_close = platform_pair(steps, platform_pair_indices[1])

        self.assertEqual(detail_close["iOS"], [{"tapOn": {"point": "6%, 9%"}}])
        self.assertEqual(detail_close["Android"], ["back"])
        self.assertEqual(player_close["iOS"][0], {"tapOn": {"point": "90%, 5%"}})
        self.assertEqual([command for command in player_close["Android"] if command == "back"], ["back", "back"])
        self.assertNotIn("back", steps)


if __name__ == "__main__":
    unittest.main()
