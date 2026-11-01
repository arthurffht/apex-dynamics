"""Exercise the installed Serena MCP over its official Python SDK, using read-only calls."""
import asyncio
import json
import os
from pathlib import Path
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

ROOT = Path(__file__).resolve().parents[1]

async def main():
    environment = os.environ.copy()
    environment["PATH"] = str(Path.home() / ".rokit" / "bin") + os.pathsep + environment["PATH"]
    executable = Path.home() / ".local" / "bin" / "serena.exe"
    server = StdioServerParameters(command=str(executable), args=[
        "start-mcp-server", "--project", str(ROOT), "--context", "codex",
        "--agent-interface", "tools", "--enable-web-dashboard", "false",
        "--open-web-dashboard", "false", "--enable-gui-log-window", "false",
    ], env=environment, cwd=str(ROOT))
    async with asyncio.timeout(90):
        async with stdio_client(server) as (read, write):
            async with ClientSession(read, write) as session:
                await session.initialize()
                tools = await session.list_tools()
                names = [tool.name for tool in tools.tools]
                if "find_symbol" not in names:
                    raise RuntimeError("Serena did not expose its symbol tool")
                result = await session.call_tool("find_symbol", {
                    "name_path_pattern": "stepWheel", "relative_path": "src/core/Tire.luau",
                    "substring_matching": True, "include_body": False,
                })
                payload = result.model_dump(mode="json")
                text = json.dumps(payload)
                if result.is_error or "stepWheel" not in text:
                    raise RuntimeError("MCP could not resolve the real Luau wheel solver")
                report = {"success": True, "tool": "find_symbol", "symbol": "Tire.stepWheel", "toolCount": len(names), "result": payload}
                output = ROOT / ".local" / "diagnostics" / "serena-mcp.json"
                output.parent.mkdir(parents=True, exist_ok=True)
                output.write_text(json.dumps(report, indent=2), encoding="utf-8")
                print(json.dumps({key: value for key, value in report.items() if key != "result"}))

asyncio.run(main())
