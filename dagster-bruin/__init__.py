from dagster_bruin import BruinAssetTranslator,BruinCliResource,BruinProject,bruin_assets
from pathlib import Path
from dagster import AssetExecutionContext, Definitions
import os

bruin_cli_resource = BruinCliResource(
    bruin_executable=os.getenv("BRUIN_EXECUTABLE_PATH"),
    bruin_pipeline_directory=os.getenv("BRUIN_PIPELINE_DIRECTORY")
)

bruin_project = BruinProject(
    bruin_cli_resource
)

bruin_asset_translator = BruinAssetTranslator(
    bruin_project=bruin_project
)

@bruin_assets(
    bruin_asset_translator=bruin_asset_translator
)
def bruin_pipelines(context : AssetExecutionContext, bruin : BruinCliResource):
    yield from bruin.cli(["run","--no-color","--no-timestamp"],context=context).stream()

defs = Definitions(
    assets = [bruin_pipelines],
    resources={
        "bruin" : bruin_cli_resource
    }
)