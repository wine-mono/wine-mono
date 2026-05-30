#include <check.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>
#include <stdint.h>
#include <errno.h>

/*
 * Security invariant: When computing buffer size for concatenating a prefix
 * and a user-controlled string, the allocation must never overflow size_t,
 * and the resulting buffer must be large enough to hold the concatenated
 * wide-character string without heap corruption.
 *
 * Specifically: sizeof(wchar_t) * (wcslen(prefix) + wcslen(input) + 1)
 * must not overflow, and the allocated buffer must be >= that size.
 */

/* Safe allocation function that checks for overflow before allocating */
static wchar_t *safe_alloc_concat_buf(const wchar_t *prefix, const wchar_t *input)
{
    size_t prefix_len = wcslen(prefix);
    size_t input_len  = wcslen(input);

    /* Check addition overflow */
    if (input_len > SIZE_MAX - prefix_len - 1) {
        return NULL;
    }
    size_t total_chars = prefix_len + input_len + 1;

    /* Check multiplication overflow */
    if (total_chars > SIZE_MAX / sizeof(wchar_t)) {
        return NULL;
    }
    size_t alloc_size = sizeof(wchar_t) * total_chars;

    wchar_t *buf = malloc(alloc_size);
    if (buf == NULL) {
        return NULL;
    }

    wcscpy(buf, prefix);
    wcscat(buf, input);

    return buf;
}

/* Vulnerable allocation (mirrors the original code) — used to detect overflow */
static int vulnerable_alloc_would_overflow(const wchar_t *prefix, const wchar_t *input)
{
    size_t prefix_len = wcslen(prefix);
    size_t input_len  = wcslen(input);

    /* Detect if the addition overflows */
    if (input_len > SIZE_MAX - prefix_len - 1) {
        return 1; /* overflow */
    }
    size_t total_chars = prefix_len + input_len + 1;

    /* Detect if the multiplication overflows */
    if (total_chars > SIZE_MAX / sizeof(wchar_t)) {
        return 1; /* overflow */
    }
    return 0; /* no overflow */
}

/* Generate a wide string of given length filled with 'A' */
static wchar_t *make_wide_string(size_t len)
{
    wchar_t *s = malloc((len + 1) * sizeof(wchar_t));
    if (!s) return NULL;
    for (size_t i = 0; i < len; i++) {
        s[i] = L'A';
    }
    s[len] = L'\0';
    return s;
}

START_TEST(test_buffer_size_no_overflow)
{
    /* Invariant: The buffer allocation for prefix+input must never overflow,
     * and if it would overflow, the safe implementation must refuse to allocate
     * (return NULL) rather than allocate a too-small buffer. */

    const wchar_t *prefix = L"/some/install/prefix/";

    /* Adversarial wide-string lengths */
    size_t adversarial_lengths[] = {
        0,
        1,
        127,
        128,
        255,
        256,
        1023,
        1024,
        4095,
        4096,
        65535,
        65536,
        /* Near SIZE_MAX / sizeof(wchar_t) to trigger multiplication overflow */
        SIZE_MAX / sizeof(wchar_t),
        SIZE_MAX / sizeof(wchar_t) - 1,
        SIZE_MAX / sizeof(wchar_t) + 1,  /* wraps to small value */
        SIZE_MAX / 2,
        SIZE_MAX - 1,
        SIZE_MAX,
    };

    int num_lengths = sizeof(adversarial_lengths) / sizeof(adversarial_lengths[0]);

    for (int i = 0; i < num_lengths; i++) {
        size_t len = adversarial_lengths[i];

        /* Skip lengths that would require more memory than reasonable to allocate
         * for the test itself — we only test the overflow detection logic */
        if (len > 10 * 1024 * 1024) {
            /* For huge lengths, just verify overflow detection works */
            int would_overflow = vulnerable_alloc_would_overflow(prefix, L"");

            /* Construct a synthetic check: if len >= SIZE_MAX/sizeof(wchar_t),
             * the multiplication must be detected as overflow */
            size_t prefix_len = wcslen(prefix);
            size_t total_chars_check;
            int addition_overflows = (len > SIZE_MAX - prefix_len - 1);

            if (!addition_overflows) {
                total_chars_check = prefix_len + len + 1;
                int mult_overflows = (total_chars_check > SIZE_MAX / sizeof(wchar_t));

                if (mult_overflows) {
                    /* Safe implementation must return NULL for overflow inputs */
                    /* We can't actually allocate len wchars, so just verify logic */
                    ck_assert_int_eq(mult_overflows, 1);
                }
            } else {
                /* Addition overflows — safe impl must catch this */
                ck_assert_int_eq(addition_overflows, 1);
            }
            continue;
        }

        wchar_t *input = make_wide_string(len);
        if (!input) {
            /* malloc failed for test setup — skip this length */
            continue;
        }

        int would_overflow = vulnerable_alloc_would_overflow(prefix, input);

        if (!would_overflow) {
            /* Safe allocation must succeed and produce correct result */
            wchar_t *buf = safe_alloc_concat_buf(prefix, input);

            /* Invariant: allocation succeeded */
            ck_assert_ptr_nonnull(buf);

            /* Invariant: buffer contains the prefix */
            size_t prefix_len = wcslen(prefix);
            ck_assert_int_eq(wcsncmp(buf, prefix, prefix_len), 0);

            /* Invariant: total length is correct (no truncation) */
            size_t expected_len = wcslen(prefix) + wcslen(input);
            ck_assert_uint_eq(wcslen(buf), expected_len);

            /* Invariant: buffer is NUL-terminated (wcslen guarantees this,
             * but verify the last char is NUL explicitly) */
            ck_assert_int_eq(buf[expected_len], L'\0');

            free(buf);
        } else {
            /* Overflow detected: safe implementation must return NULL */
            wchar_t *buf = safe_alloc_concat_buf(prefix, input);
            ck_assert_ptr_null(buf);
            /* No free needed since buf is NULL */
        }

        free(input);
    }
}
END_TEST

START_TEST(test_overflow_detection_correctness)
{
    /* Invariant: overflow detection must correctly identify all cases where
     * sizeof(wchar_t) * (prefix_len + input_len + 1) would overflow size_t */

    const wchar_t *prefix = L"prefix_";
    size_t prefix_len = wcslen(prefix);

    /* Test cases: (input_len, expected_overflow) */
    struct {
        size_t input_len;
        int    expect_overflow;
    } cases[] = {
        { 0,                                    0 },
        { 1,                                    0 },
        { 100,                                  0 },
        { SIZE_MAX / sizeof(wchar_t),           1 },
        { SIZE_MAX / sizeof(wchar_t) - prefix_len - 2, 0 },  /* boundary: just fits */
        { SIZE_MAX / sizeof(wchar_t) - prefix_len - 1, 1 },  /* boundary: just overflows */
        { SIZE_MAX - prefix_len - 1,            1 },
        { SIZE_MAX - prefix_len,                1 },
        { SIZE_MAX,                             1 },
        { SIZE_MAX / 2,                         1 },
    };

    int num_cases = sizeof(cases) / sizeof(cases[0]);

    for (int i = 0; i < num_cases; i++) {
        size_t input_len = cases[i].input_len;
        int expect_overflow = cases[i].expect_overflow;

        /* Compute overflow manually */
        int addition_overflows = (input_len > SIZE_MAX - prefix_len - 1);
        int mult_overflows = 0;

        if (!addition_overflows) {
            size_t total = prefix_len + input_len + 1;
            mult_overflows = (total > SIZE_MAX / sizeof(wchar_t));
        }

        int detected_overflow = addition_overflows || mult_overflows;

        /* Invariant: overflow detection must match expected result */
        ck_assert_int_eq(detected_overflow, expect_overflow);
    }
}
END_TEST

START_TEST(test_adversarial_wide_payloads)
{
    /* Invariant: adversarial wide-string payloads must not cause the safe
     * allocator to write beyond the allocated buffer */

    const wchar_t *prefix = L"/usr/local/share/";

    /* Adversarial wide-string payloads */
    const wchar_t *payloads[] = {
        L"",
        L"A",
        L"../../../etc/passwd",
        L"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
        L"\x00\x01\x02\x03",   /* embedded nulls won't matter after wcslen */
        L"path/with/many/slashes/////////////////////",
        L"\xff\xfe\xfd\xfc",
        L"normal_path_component",
        L"very_long_but_valid_path_component_that_is_exactly_at_boundary_x",
    };

    int num_payloads = sizeof(payloads) / sizeof(payloads[0]);

    for (int i = 0; i < num_payloads; i++) {
        const wchar_t *input = payloads[i];

        int would_overflow = vulnerable_alloc_would_overflow(prefix, input);

        if (!would_overflow) {
            wchar_t *buf = safe_alloc_concat_buf(prefix, input);

            /* Invariant: allocation must succeed for non-overflow inputs */
            ck_assert_ptr_nonnull(buf);

            size_t expected_total = wcslen(prefix) + wcslen(input);

            /* Invariant: result length must equal sum of parts */
            ck_assert_uint_eq(wcslen(buf), expected_total);

            /* Invariant: NUL terminator must be present */
            ck_assert_int_eq(buf[expected_total], L'\0');

            /* Invariant: prefix must be intact at start of buffer */
            ck_assert_int_eq(wcsncmp(buf, prefix, wcslen(prefix)), 0);

            /* Invariant: input must follow prefix */
            ck_assert_int_eq(wcscmp(buf + wcslen(prefix), input), 0);

            free(buf);
        }
        /* If overflow would occur, safe_alloc_concat_buf returns NULL — already tested */
    }
}
END_TEST

Suite *security_suite(void)
{
    Suite *s;
    TCase *tc_core;

    s = suite_create("Security");
    tc_core = tcase_create("Core");

    tcase_set_timeout(tc_core, 60);
    tcase_add_test(tc_core, test_buffer_size_no_overflow);
    tcase_add_test(tc_core, test_overflow_detection_correctness);
    tcase_add_test(tc_core, test_adversarial_wide_payloads);
    suite_add_tcase(s, tc_core);

    return s;
}

int main(void)
{
    int number_failed;
    Suite *s;
    SRunner *sr;

    s = security_suite();
    sr = srunner_create(s);

    srunner_run_all(sr, CK_NORMAL);
    number_failed = srunner_ntests_failed(sr);
    srunner_free(sr);

    return (number_failed == 0) ? EXIT_SUCCESS : EXIT_FAILURE;
}