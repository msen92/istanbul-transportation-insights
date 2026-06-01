from dagster import (
    ConfigurableResource,
    AssetExecutionContext,
    AssetKey,
    AssetMaterialization,
    AssetCheckEvaluation,
    Output,
    MetadataValue
)
import subprocess
import json
import re
import sys

_FINISHED_RE = re.compile(r"Finished: (.+?) \((.+?)\)$")

_FAILED_RE = re.compile(r"Failed: (.+?) \((.+?)\)$")

_ANSI_ESCAPE_RE = re.compile(r"\x1b\[[0-9;]*m|\[[0-9;]*m")

def _strip_ansi(line: str) -> str:
    return _ANSI_ESCAPE_RE.sub("", line).strip()

class BruinCliResource(ConfigurableResource):
    bruin_executable: str = "bruin"
    bruin_pipeline_directory: str

    def cli(self, args: list[str], context: AssetExecutionContext = None):
        return BruinCliInvocation(
            executable=self.bruin_executable,
            args=args,
            context=context,
            cwd = self.bruin_pipeline_directory
        )

class BruinCliInvocation:
    def __init__(self, executable, args, context, cwd):
        self._exe = executable
        self._args = args
        self._context = context
        self._cwd = cwd
    
    def _parse_duration_seconds(self,duration_str: str) -> float:
        """Convert '2m33.65s', '4ms', '45s', '1h2m3s' to total seconds as a float."""
        total = 0.0
        for value, unit in re.findall(r"([\d.]+)(ms|h|m|s)", duration_str):
            v = float(value)
            if unit == "ms":
                total += v / 1000
            elif unit == "s":
                total += v
            elif unit == "m":
                total += v * 60
            elif unit == "h":
                total += v * 3600
        return total

    def stream(self):
        args = self._args
        if len(self._context.assets_def._specs_by_key) > len(self._context.selected_asset_keys):
            args.append("--selector")
            for asset_key in self._context.selected_asset_keys:
                args.append(asset_key.to_user_string())

        cmd = [self._exe] + args

        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, cwd=self._cwd)
        with process.stdout:
            for raw_line in process.stdout or []:
                line = _strip_ansi(raw_line.rstrip())
                if not line:
                    continue

                m = _FINISHED_RE.match(line)
                if m:
                    asset_name = m.group(1)
                    duration_str = m.group(2)
                    duration = self._parse_duration_seconds(duration_str)
                    if asset_name.count(':') == 2:
                        check_name_splited = asset_name.split(':')
                        check_name = '_'.join(check_name_splited[1:]).replace('-','_')
                        asset_name = check_name_splited[0]
                        yield AssetCheckEvaluation(
                            check_name=check_name,
                            asset_key=AssetKey(asset_name),
                            passed=True,
                        )
                        yield Output(
                            value=None,
                            output_name=f"{asset_name.replace('.','_')}_{check_name}"
                        )
                        continue

                    yield AssetMaterialization(
                        asset_key=AssetKey(asset_name),
                        metadata={
                            "execution_time_s": MetadataValue.float(duration)
                        }
                    )

                m = _FAILED_RE.match(line)
                if m:
                    asset_name = m.group(1)
                    if asset_name.count(':') == 2:
                        check_name_splited = asset_name.split(':')
                        check_name = '_'.join(check_name_splited[1:]).replace('-','_')
                        asset_name = check_name_splited[0]
                        yield AssetCheckEvaluation(
                            check_name=check_name,
                            asset_key=AssetKey(asset_name),
                            passed=False,
                        )
                        yield Output(
                            value=None,
                            output_name=f"{asset_name.replace('.','_')}_{check_name}"
                        )
                self._context.log.info(line)
    
    def _get_raw_output(self) -> str:
        try:
            cmd = [self._exe] + self._args
            process = subprocess.Popen(
                args=cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                cwd=self._cwd
            )
            all_output = []
            with process.stdout:
                for raw_line in process.stdout or []:
                    all_output.append(raw_line.decode().strip())

            return "\n".join(all_output)
        except subprocess.CalledProcessError as e:
            raise RuntimeError(f"Bruin CLI Command failed: {e.stderr or e.stdout}")

    def get_result_as_dict(self) -> dict:
        return json.loads(self._get_raw_output())
