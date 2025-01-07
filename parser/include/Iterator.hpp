#pragma once

#include <vector>
#include <stdexcept>

template<typename T>
class Iterator {
private:
    std::vector<T> vec;
    size_t currentIndex;

public:
    Iterator(const std::vector<T>& source)
        : vec(source), currentIndex(0) {}

    Iterator operator+(int n) const {
        Iterator temp = *this;
        temp.currentIndex += n;
        if (temp.currentIndex > temp.vec.size()) {
            throw std::out_of_range("Iterator out of range");
        }
        return temp;
    }

    Iterator& operator+=(int n) {
        currentIndex += n;
        if (currentIndex > vec.size()) {
            throw std::out_of_range("Iterator out of range");
        }
        return *this;
    }

    Iterator& operator++() {
        if (currentIndex < vec.size()) ++currentIndex;
        return *this;
    }

    Iterator operator++(int) {
        Iterator temp = *this;
        ++(*this);
        return temp;
    }

    T& operator*() {
        if (currentIndex >= vec.size()) throw std::out_of_range("Iterator out of range");
        return vec[currentIndex];
    }

    T* operator->() {
        if (currentIndex >= vec.size()) throw std::out_of_range("Iterator out of range");
        return &vec[currentIndex];
    }

    bool operator==(const Iterator& other) const {
        return currentIndex == other.currentIndex && vec == other.vec;
    }

    bool operator!=(const Iterator& other) const {
        return !(*this == other);
    }

    bool hasNext() const {
        return currentIndex < vec.size() - 1;
    }
};
