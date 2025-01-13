class DataValidator:
    def validate_data(self, expected: list, actual: list) -> dict:
        """
        Validate the actual data against expected data.
        """
        matched = [row for row in actual if row in expected]
        unmatched = [row for row in actual if row not in expected]
        return {
            "matched": matched,
            "unmatched": unmatched,
            "accuracy": len(matched) / len(expected) if expected else 0
        }
