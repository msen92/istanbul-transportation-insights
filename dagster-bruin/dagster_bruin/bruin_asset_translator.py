from typing import Sequence
from dagster import (
    AssetSpec,
    AssetCheckSpec,
    AssetKey,
    TableColumn,
    TableSchema
)
from .bruin_project import BruinProject
from pathlib import Path

_BRUIN_TYPE_TO_KIND = {
    "bq.sql": "bigquery",
    "bq.sensor.query": "bigquery",
    "python": "python",
    "ingestr" : "yaml"
}

class BruinAssetTranslator:
    """Translates Bruin JSON metadata structures into Dagster Asset definitions."""
    
    def __init__(self, bruin_project: BruinProject):
        self.bruin = bruin_project

    def asset_description_builder(self,description_text : str, definition_file_contents : str, kind : str) -> str:
        markdown_type = "```sql"
        if kind == "python":
            markdown_type = "```python"
        complete_description_text = (
            description_text +
            f"\n\n# Raw executable:\n{markdown_type}\n" +
            definition_file_contents +
            "\n```"
        )
        return complete_description_text

    def get_asset_specs(self) -> tuple[Sequence[AssetSpec],Sequence[AssetCheckSpec]]:
        manifest = self.bruin.pipelines
        specs = []
        check_specs = []
        
        for asset in manifest.get("assets", []):
            asset_name = asset["name"]
            dependencies = [dep["value"] for dep in asset.get("upstreams", [])]
            column_metadata = []
            definition_file_path = Path(asset.get("definition_file").get("path"))
            definition_file_contents = ""
            if definition_file_path.exists():
                with open(definition_file_path,'r') as f:
                    definition_file_contents = f.read()
            # Map Bruin Data Quality Checks to native Dagster AssetChecks
            for column in asset.get("columns", []):
                column_metadata.append(
                    TableColumn(
                        name= column.get("name"),
                        type = column.get("type"),
                        description = column.get("description"),
                    )
                )
                for check in column.get("checks", []):
                    check_specs.append(
                        AssetCheckSpec(
                            name=f"{column['name']}_{check['name']}",
                            asset=AssetKey(asset_name),
                            description=check['description']
                        )
                    )
            for custom_check in asset.get("custom_checks"):
                check_specs.append(
                    AssetCheckSpec(
                        name=f"custom_check_{custom_check['name'].replace('-','_')}",
                        asset=AssetKey(asset_name),
                        description=custom_check['description'],
                        metadata={"query" : custom_check['query']}
                    )
                )
            asset_kind = _BRUIN_TYPE_TO_KIND[asset.get("type")]
            specs.append(
                AssetSpec(
                    key=asset_name,
                    deps=dependencies,
                    metadata={
                        "Domains" : asset.get("domains"),
                        "Type" : asset.get("type"),
                        "dagster/column_schema" : TableSchema(
                            columns=column_metadata
                        )
                    },
                    description=self.asset_description_builder(asset.get("description",""),definition_file_contents,asset_kind) ,
                    owners=[self.sanitize_owner(asset.get("owner"))],
                    kinds=[asset_kind],
                    tags={tag:"1" for tag in asset.get("tags")}
                )
            )
        return specs,check_specs
    
    def sanitize_owner(self,owner : str) -> str:
        if owner in [None, ""]:
            return "team:unknown"
        return owner