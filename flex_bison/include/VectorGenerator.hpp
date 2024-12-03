#pragma once

#include <vector>
#include <iostream>

/**
 * Я памятник себе воздвиг нерукотворный,
 * К нему не зарастет народная тропа,
 * Вознесся выше он главою непокорной
 * Александрийского столпа.
 * 
 * Нет, весь я не умру — душа в заветной лире
 * Мой прах переживет и тленья убежит —
 * И славен буду я, доколь в подлунном мире
 * Жив будет хоть один пиит.
 * 
 * Слух обо мне пройдет по всей Руси великой,
 * И назовет меня всяк сущий в ней язык,
 * И гордый внук славян, и финн, и ныне дикой
 * Тунгус, и друг степей калмык.
 * 
 * И долго буду тем любезен я народу,
 * Что чувства добрые я лирой пробуждал,
 * Что в мой жестокий век восславил я Свободу
 * И милость к падшим призывал.
 * 
 * Веленью божию, о муза, будь послушна,
 * Обиды не страшась, не требуя венца,
 * Хвалу и клевету приемли равнодушно
 * И не оспоривай глупца.
*/
template <typename T>
class VectorGenerator {
public:
    VectorGenerator(const std::vector<T>& vec, T defaultElem)
        : vec(vec), defaultElem(defaultElem), curIndex(0) {}

    T next() {
        if (curIndex < vec.size()) {
            return vec[curIndex++];
        } 
        return defaultElem;
    }

    std::vector<T> getVector() const {
        std::vector<T> copy;

        for (auto& elem : vec) {
            copy.push_back(elem);
        }

        return copy;
    }

private:
    std::vector<T> vec;   
    T defaultElem;        
    size_t curIndex;      
};
