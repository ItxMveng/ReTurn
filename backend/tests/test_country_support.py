import pytest
from pydantic import ValidationError

from app.core.countries import normalize_country_code
from app.schemas.declaration import DeclarationCreate
from app.schemas.user import UserUpdate


class TestNormalizeCountryCode:
    def test_uppercases_and_trims(self):
        assert normalize_country_code(" cm ") == "CM"

    def test_empty_or_none_means_unknown(self):
        assert normalize_country_code(None) is None
        assert normalize_country_code("  ") is None

    @pytest.mark.parametrize("bad", ["C", "CMR", "C1", "é", "12"])
    def test_invalid_codes_are_rejected(self, bad):
        with pytest.raises(ValueError):
            normalize_country_code(bad)


class TestSchemas:
    def test_declaration_country_is_normalized(self):
        d = DeclarationCreate(
            declaration_type="lost", document_type="cni", country_code="fr"
        )
        assert d.country_code == "FR"

    def test_declaration_country_is_optional(self):
        d = DeclarationCreate(declaration_type="found", document_type="passport")
        assert d.country_code is None

    def test_declaration_rejects_invalid_country(self):
        with pytest.raises(ValidationError):
            DeclarationCreate(
                declaration_type="lost", document_type="cni", country_code="XYZ"
            )

    def test_profile_country_is_normalized(self):
        assert UserUpdate(country_code="cm").country_code == "CM"


class TestInternationalPhones:
    @pytest.mark.parametrize(
        "number",
        [
            "+237690000000",   # Cameroun
            "+33612345678",    # France
            "+4915112345678",  # Allemagne
            "+4512345678",     # Danemark (8 chiffres nationaux)
        ],
    )
    def test_accepts_numbers_from_any_country(self, number):
        assert UserUpdate(phone_number=number).phone_number == number

    @pytest.mark.parametrize("bad", ["abc", "+33 6 12", "12345", "++33612345678"])
    def test_rejects_invalid_numbers(self, bad):
        with pytest.raises(ValidationError):
            UserUpdate(phone_number=bad)
