import re


def normalize_phone(raw: str) -> str:
    """Приводит номер к единому виду +996XXXXXXXXX.

    '755750238', '0755750238', '996755750238', '+996 755 750-238'
    → все дают '+996755750238'.
    """
    digits = re.sub(r'\D', '', raw or '')
    if not digits:
        return ''
    if digits.startswith('996'):
        digits = digits[3:]
    elif digits.startswith('0'):
        digits = digits.lstrip('0')
    digits = digits[-9:]  # последние 9 цифр — национальный номер
    if not digits:
        return ''
    return '+996' + digits
