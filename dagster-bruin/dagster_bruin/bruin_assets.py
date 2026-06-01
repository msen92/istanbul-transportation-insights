from .bruin_asset_translator import BruinAssetTranslator
from dagster import multi_asset

def bruin_assets(bruin_asset_translator : BruinAssetTranslator) -> multi_asset:
    specs,checks = bruin_asset_translator.get_asset_specs()

    return multi_asset(
        specs=specs,
        check_specs=checks,
        can_subset=True
    )
