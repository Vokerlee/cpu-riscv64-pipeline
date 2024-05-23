#include <elfio/elfio.hpp>
#include <vector>
#include <iostream>
#include <cstdint>

namespace elf64_parser {

struct Elf64Seg {
    size_t start_addr;
    std::vector<uint32_t> data;
};

struct Elf64Data {
    size_t entry;
    std::vector<Elf64Seg> segs;
};

ELFIO::elfio get_riscv64_elf_reader(const std::string& filename)
{
    ELFIO::elfio reader;
    reader.load(filename);

    if (reader.get_class() != ELFIO::ELFCLASS64) {
        std::cerr << "Executable must be ELF64 class" << std::endl;
    }

    if (reader.get_machine() != ELFIO::EM_RISCV) {
        std::cerr << "Machine must be RISC-V" << std::endl;
    }

    return reader;
}

ELFIO::Elf64_Addr load_riscv64_elf(const std::string &filename, void *dst_data)
{
    ELFIO::elfio reader = get_riscv64_elf_reader(filename);

    ELFIO::Elf_Half n_segments = reader.segments.size();
    for (size_t i = 0; i < n_segments; ++i) {
        const ELFIO::segment *pseg = reader.segments[i];
        const void *seg_data = pseg->get_data();
        size_t file_size = pseg->get_file_size();
        size_t start_addr = pseg->get_virtual_address();

        std::memcpy(static_cast<uint8_t *>(dst_data) + start_addr, seg_data, file_size);
    }

    return reader.get_entry();
}

Elf64Data get_riscv64_elf_data(const std::string &filename)
{
    ELFIO::elfio reader = get_riscv64_elf_reader(filename);
    Elf64Data elf_data;

    elf_data.entry = reader.get_entry();

    ELFIO::Elf_Half n_segments = reader.segments.size();
    for (size_t i = 0; i < n_segments; ++i) {
        const ELFIO::segment* pseg = reader.segments[i];
        const void *seg_data = pseg->get_data();
        uint32_t file_size = pseg->get_file_size();
        uint32_t start_addr = pseg->get_virtual_address();

        std::vector<uint32_t> seg_data_v(file_size / sizeof(uint32_t));
        std::memcpy(seg_data_v.data(), seg_data, file_size);

        Elf64Seg seg_info { start_addr, std::move(seg_data_v) };
        elf_data.segs.push_back(std::move(seg_info));
    }

    return elf_data;
}

} // namespace elf64_parser
