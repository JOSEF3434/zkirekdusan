#include <cstdint>
#include <cstddef>
#include <cstring>

// Compatibility shims for MSVC 14.3+ (VS2022) vectorized STL functions.
// When linking against precompiled static libraries (like Firebase C++ SDK 13.x)
// built with VS2022 while compiling with VS2019, these symbols are missing
// from the VS2019 STL runtime.

extern "C" {

// __std_find_trivial_*
const void* __stdcall __std_find_trivial_1(const void* _First, const void* _Last, uint8_t _Val) noexcept {
    const uint8_t* cur = static_cast<const uint8_t*>(_First);
    const uint8_t* last = static_cast<const uint8_t*>(_Last);
    while (cur != last) {
        if (*cur == _Val) return cur;
        ++cur;
    }
    return _Last;
}

const void* __stdcall __std_find_trivial_2(const void* _First, const void* _Last, uint16_t _Val) noexcept {
    const uint16_t* cur = static_cast<const uint16_t*>(_First);
    const uint16_t* last = static_cast<const uint16_t*>(_Last);
    while (cur != last) {
        if (*cur == _Val) return cur;
        ++cur;
    }
    return _Last;
}

const void* __stdcall __std_find_trivial_4(const void* _First, const void* _Last, uint32_t _Val) noexcept {
    const uint32_t* cur = static_cast<const uint32_t*>(_First);
    const uint32_t* last = static_cast<const uint32_t*>(_Last);
    while (cur != last) {
        if (*cur == _Val) return cur;
        ++cur;
    }
    return _Last;
}

const void* __stdcall __std_find_trivial_8(const void* _First, const void* _Last, uint64_t _Val) noexcept {
    const uint64_t* cur = static_cast<const uint64_t*>(_First);
    const uint64_t* last = static_cast<const uint64_t*>(_Last);
    while (cur != last) {
        if (*cur == _Val) return cur;
        ++cur;
    }
    return _Last;
}

// __std_find_last_trivial_*
const void* __stdcall __std_find_last_trivial_1(const void* _First, const void* _Last, uint8_t _Val) noexcept {
    const uint8_t* cur = static_cast<const uint8_t*>(_Last);
    const uint8_t* first = static_cast<const uint8_t*>(_First);
    while (cur != first) {
        --cur;
        if (*cur == _Val) return cur;
    }
    return _Last;
}

const void* __stdcall __std_find_last_trivial_2(const void* _First, const void* _Last, uint16_t _Val) noexcept {
    const uint16_t* cur = static_cast<const uint16_t*>(_Last);
    const uint16_t* first = static_cast<const uint16_t*>(_First);
    while (cur != first) {
        --cur;
        if (*cur == _Val) return cur;
    }
    return _Last;
}

const void* __stdcall __std_find_last_trivial_4(const void* _First, const void* _Last, uint32_t _Val) noexcept {
    const uint32_t* cur = static_cast<const uint32_t*>(_Last);
    const uint32_t* first = static_cast<const uint32_t*>(_First);
    while (cur != first) {
        --cur;
        if (*cur == _Val) return cur;
    }
    return _Last;
}

const void* __stdcall __std_find_last_trivial_8(const void* _First, const void* _Last, uint64_t _Val) noexcept {
    const uint64_t* cur = static_cast<const uint64_t*>(_Last);
    const uint64_t* first = static_cast<const uint64_t*>(_First);
    while (cur != first) {
        --cur;
        if (*cur == _Val) return cur;
    }
    return _Last;
}

// __std_remove_*
void* __stdcall __std_remove_1(void* _First, void* _Last, uint8_t _Val) noexcept {
    uint8_t* cur = static_cast<uint8_t*>(_First);
    uint8_t* last = static_cast<uint8_t*>(_Last);
    uint8_t* result = cur;
    while (cur != last) {
        if (*cur != _Val) {
            *result = *cur;
            ++result;
        }
        ++cur;
    }
    return result;
}

void* __stdcall __std_remove_2(void* _First, void* _Last, uint16_t _Val) noexcept {
    uint16_t* cur = static_cast<uint16_t*>(_First);
    uint16_t* last = static_cast<uint16_t*>(_Last);
    uint16_t* result = cur;
    while (cur != last) {
        if (*cur != _Val) {
            *result = *cur;
            ++result;
        }
        ++cur;
    }
    return result;
}

void* __stdcall __std_remove_4(void* _First, void* _Last, uint32_t _Val) noexcept {
    uint32_t* cur = static_cast<uint32_t*>(_First);
    uint32_t* last = static_cast<uint32_t*>(_Last);
    uint32_t* result = cur;
    while (cur != last) {
        if (*cur != _Val) {
            *result = *cur;
            ++result;
        }
        ++cur;
    }
    return result;
}

void* __stdcall __std_remove_8(void* _First, void* _Last, uint64_t _Val) noexcept {
    uint64_t* cur = static_cast<uint64_t*>(_First);
    uint64_t* last = static_cast<uint64_t*>(_Last);
    uint64_t* result = cur;
    while (cur != last) {
        if (*cur != _Val) {
            *result = *cur;
            ++result;
        }
        ++cur;
    }
    return result;
}

// __std_find_first_of_trivial_pos_*
size_t __stdcall __std_find_first_of_trivial_pos_1(
    const void* const _Haystack,
    const size_t _Haystack_length,
    const void* const _Needle,
    const size_t _Needle_length) noexcept {
    const uint8_t* h = static_cast<const uint8_t*>(_Haystack);
    const uint8_t* n = static_cast<const uint8_t*>(_Needle);
    for (size_t i = 0; i < _Haystack_length; ++i) {
        for (size_t j = 0; j < _Needle_length; ++j) {
            if (h[i] == n[j]) {
                return i;
            }
        }
    }
    return static_cast<size_t>(-1);
}

// __std_find_last_of_trivial_pos_*
size_t __stdcall __std_find_last_of_trivial_pos_1(
    const void* const _Haystack,
    const size_t _Haystack_length,
    const void* const _Needle,
    const size_t _Needle_length) noexcept {
    const uint8_t* h = static_cast<const uint8_t*>(_Haystack);
    const uint8_t* n = static_cast<const uint8_t*>(_Needle);
    for (size_t i = _Haystack_length; i > 0; --i) {
        for (size_t j = 0; j < _Needle_length; ++j) {
            if (h[i - 1] == n[j]) {
                return i - 1;
            }
        }
    }
    return static_cast<size_t>(-1);
}

// __std_find_first_not_of_trivial_pos_1
size_t __stdcall __std_find_first_not_of_trivial_pos_1(
    const void* const _Haystack,
    const size_t _Haystack_length,
    const void* const _Needle,
    const size_t _Needle_length) noexcept {
    const uint8_t* h = static_cast<const uint8_t*>(_Haystack);
    const uint8_t* n = static_cast<const uint8_t*>(_Needle);
    for (size_t i = 0; i < _Haystack_length; ++i) {
        bool match = false;
        for (size_t j = 0; j < _Needle_length; ++j) {
            if (h[i] == n[j]) {
                match = true;
                break;
            }
        }
        if (!match) return i;
    }
    return static_cast<size_t>(-1);
}

// __std_find_last_not_of_trivial_pos_1
size_t __stdcall __std_find_last_not_of_trivial_pos_1(
    const void* const _Haystack,
    const size_t _Haystack_length,
    const void* const _Needle,
    const size_t _Needle_length) noexcept {
    const uint8_t* h = static_cast<const uint8_t*>(_Haystack);
    const uint8_t* n = static_cast<const uint8_t*>(_Needle);
    for (size_t i = _Haystack_length; i > 0; --i) {
        bool match = false;
        for (size_t j = 0; j < _Needle_length; ++j) {
            if (h[i - 1] == n[j]) {
                match = true;
                break;
            }
        }
        if (!match) return i - 1;
    }
    return static_cast<size_t>(-1);
}

} // extern "C"
