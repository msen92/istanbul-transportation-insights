
from .bruin_cli_resource import BruinCliResource
from pathlib import Path

class BruinProject:
    def __init__(self,bruin_cli_resource : BruinCliResource):
        self.bruin_cli_resource = bruin_cli_resource
        self.pipelines = self._parse_pipelines()

    def _parse_pipelines(self):
        for dir in Path(self.bruin_cli_resource.bruin_pipeline_directory).iterdir():
            if dir.is_dir():
                cli_invokation = self.bruin_cli_resource.cli(["internal", "parse-pipeline",dir])
        return cli_invokation.get_result_as_dict()
