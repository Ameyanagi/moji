from moji import (
    UNICODE_DATA_VERSION,
    AmbiguousWidth,
    grapheme_width,
    scalar_width,
    text_width,
)
from std.testing import TestSuite, assert_equal


def _assert_fixture(
    label: StringSlice, text: StringSlice, expected_narrow: Int, expected_wide: Int
) raises:
    assert_equal(text_width(text), expected_narrow, msg=String(label))
    assert_equal(
        text_width(text, AmbiguousWidth.WIDE), expected_wide, msg=String(label)
    )

    var narrow_sum = 0
    var wide_sum = 0
    for grapheme in text.graphemes():
        narrow_sum += grapheme_width(grapheme)
        wide_sum += grapheme_width(grapheme, AmbiguousWidth.WIDE)
    assert_equal(text_width(text), narrow_sum, msg=String(label))
    assert_equal(text_width(text, AmbiguousWidth.WIDE), wide_sum, msg=String(label))


def _first_scalar_width(
    text: StringSlice, ambiguous: AmbiguousWidth = AmbiguousWidth.NARROW
) -> Int:
    for scalar in text.codepoints():
        return scalar_width(scalar, ambiguous)
    return -1


def test_unicode_data_version() raises:
    assert_equal(UNICODE_DATA_VERSION, "17.0.0")


def test_cjk_width_fixtures() raises:
    _assert_fixture("cjk_beijing", "北京", 4, 4)
    _assert_fixture("cjk_hiragana", "こんにちは", 10, 10)
    _assert_fixture("cjk_fullwidth_a", "Ａ", 2, 2)
    _assert_fixture("cjk_halfwidth_kana", "ｶﾀｶﾅ", 4, 4)
    _assert_fixture("cjk_mixed", "a北京b", 6, 6)


def test_emoji_width_fixtures() raises:
    _assert_fixture("emoji_family_zwj", "👨‍👩‍👧‍👦", 2, 2)
    _assert_fixture("emoji_flag_jp", "🇯🇵", 2, 2)
    _assert_fixture("emoji_umbrella_vs16", "☂️", 2, 2)
    _assert_fixture("emoji_umbrella_plain", "☂", 1, 1)
    _assert_fixture("emoji_thumbs_skin", "👍🏽", 2, 2)
    _assert_fixture("emoji_keycap", "1️⃣", 2, 2)


def test_combining_width_fixtures() raises:
    _assert_fixture("combining_e_acute", "é", 1, 1)
    _assert_fixture("combining_stack", "à̖", 1, 1)
    _assert_fixture("combining_devanagari", "क्", 1, 1)


def test_control_width_fixtures() raises:
    _assert_fixture("control_tab", "\t", 0, 0)
    _assert_fixture("control_nul", chr(0), 0, 0)
    _assert_fixture("control_esc", "\x1b", 0, 0)
    _assert_fixture("control_del", "\x7f", 0, 0)
    _assert_fixture("control_c1", chr(0x85), 0, 0)
    _assert_fixture("control_mixed", "a\tb\x1bc", 3, 3)


def test_default_ignorable_width_fixtures() raises:
    _assert_fixture("zwsp", "​", 0, 0)
    _assert_fixture("soft_hyphen", "­", 0, 0)
    _assert_fixture("zwj_alone", "‍", 0, 0)


def test_ambiguous_width_fixtures() raises:
    _assert_fixture("ambiguous_section", "§", 1, 2)
    _assert_fixture("ambiguous_plusminus", "±", 1, 2)
    _assert_fixture("ambiguous_alpha", "α", 1, 2)
    _assert_fixture("ambiguous_circled_one", "①", 1, 2)


def test_scalar_width_fixtures() raises:
    assert_equal(_first_scalar_width("京"), 2)
    assert_equal(_first_scalar_width("京", AmbiguousWidth.WIDE), 2)
    assert_equal(_first_scalar_width("§"), 1)
    assert_equal(_first_scalar_width("§", AmbiguousWidth.WIDE), 2)
    assert_equal(_first_scalar_width("\x7f"), 0)
    assert_equal(_first_scalar_width("\x7f", AmbiguousWidth.WIDE), 0)
    assert_equal(_first_scalar_width("̀"), 0)
    assert_equal(_first_scalar_width("̀", AmbiguousWidth.WIDE), 0)


def test_flag_grapheme_width() raises:
    assert_equal(grapheme_width("🇯🇵"), 2)
    assert_equal(grapheme_width("🇯🇵", AmbiguousWidth.WIDE), 2)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
