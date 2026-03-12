"""PT-BR: Testes de smoke para o CLI / EN: Smoke tests for the CLI."""

import unittest
from contextlib import redirect_stdout
from io import StringIO

from bouncer.__main__ import main


class MainEntrypointTest(unittest.TestCase):
    def test_main_prints_bootstrap_message(self) -> None:
        buffer = StringIO()

        with redirect_stdout(buffer):
            main()

        self.assertEqual(
            buffer.getvalue().strip(),
            "Bouncer bootstrap is configured. Application logic will be added later.",
        )


if __name__ == "__main__":
    unittest.main()
