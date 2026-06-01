from dagster._core.libraries import DagsterLibraryRegistry
from .bruin_project import BruinProject
from .bruin_asset_translator import BruinAssetTranslator
from .bruin_cli_resource import BruinCliResource
from .bruin_assets import bruin_assets

__all__ = ["BruinProject", "BruinAssetTranslator","BruinCliResource","bruin_assets"]

__version__ = "0.0.1"

DagsterLibraryRegistry.register(
    "dagster-bruin", __version__, is_dagster_package=False
)
