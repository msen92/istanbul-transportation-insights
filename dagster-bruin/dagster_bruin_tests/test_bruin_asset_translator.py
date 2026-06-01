import pytest
import json
from dagster_bruin import BruinProject, BruinAssetTranslator, BruinCliResource
from pathlib import Path

def test_bruin_asset_creation():
    tests_dir = Path(__file__).parent
    manifest_fixture_path = tests_dir / "manifest_fixture.json"
    def mock_manifest_file(cls):
        with open(manifest_fixture_path,"r") as file:
            return json.loads(file.read())
    
    bruin_cli_resource = BruinCliResource(
        bruin_executable="bruin",
        bruin_pipeline_directory="."
    )
    pytest.MonkeyPatch().setattr(BruinProject, "_parse_pipelines", mock_manifest_file)
    translator = BruinAssetTranslator(bruin_project=BruinProject(bruin_cli_resource))
    assets,checks = translator.get_asset_specs()
    assert len(assets) == 3
    assert len(checks) == 1