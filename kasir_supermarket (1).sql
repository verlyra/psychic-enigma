-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Waktu pembuatan: 17 Jun 2026 pada 06.12
-- Versi server: 10.4.32-MariaDB
-- Versi PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `kasir_supermarket`
--

-- --------------------------------------------------------

--
-- Struktur dari tabel `detail_transaksi`
--

CREATE TABLE `detail_transaksi` (
  `id` int(11) NOT NULL,
  `id_transaksi` int(11) NOT NULL,
  `id_product` int(11) NOT NULL,
  `qty` int(11) NOT NULL,
  `harga_beli` decimal(15,2) NOT NULL,
  `harga_jual` decimal(15,2) NOT NULL,
  `subtotal` decimal(15,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `master_gudang`
--

CREATE TABLE `master_gudang` (
  `id` int(11) NOT NULL,
  `nama_gudang` varchar(100) NOT NULL,
  `lokasi` varchar(255) NOT NULL,
  `nama_pic` varchar(100) DEFAULT NULL,
  `no_telp` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `master_gudang`
--

INSERT INTO `master_gudang` (`id`, `nama_gudang`, `lokasi`, `nama_pic`, `no_telp`) VALUES
(1, 'CBD', 'CILEDUG', NULL, NULL),
(2, 'BINTARO', 'BINTARO SEKTOR 3', NULL, NULL),
(3, 'SMS', 'Kota tangerang', NULL, NULL);

-- --------------------------------------------------------

--
-- Struktur dari tabel `master_kategori`
--

CREATE TABLE `master_kategori` (
  `id` int(11) NOT NULL,
  `nama_kategori` varchar(255) NOT NULL,
  `deskripsi` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `master_kategori`
--

INSERT INTO `master_kategori` (`id`, `nama_kategori`, `deskripsi`) VALUES
(1, 'FOOD', 'MAKANAN'),
(2, 'DRINK', NULL),
(3, 'SNACK', NULL),
(4, 'OTHER', NULL),
(5, 'STATIONARY', NULL);

-- --------------------------------------------------------

--
-- Struktur dari tabel `master_product`
--

CREATE TABLE `master_product` (
  `id` int(11) NOT NULL,
  `nama_produk` varchar(100) NOT NULL,
  `merk` varchar(100) DEFAULT NULL,
  `harga_beli` decimal(10,2) NOT NULL DEFAULT 0.00,
  `harga_jual` decimal(10,2) NOT NULL,
  `stok` int(11) NOT NULL DEFAULT 0,
  `deskripsi` text DEFAULT NULL,
  `image_url` text DEFAULT NULL,
  `id_gudang` int(11) DEFAULT NULL,
  `id_kategori` int(11) DEFAULT NULL,
  `id_ukuran` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `master_product`
--

INSERT INTO `master_product` (`id`, `nama_produk`, `merk`, `harga_beli`, `harga_jual`, `stok`, `deskripsi`, `image_url`, `id_gudang`, `id_kategori`, `id_ukuran`) VALUES
(1, 'Oreo', NULL, 0.00, 10000.00, 1000, 'Oreo memiliki penampilan yang khas, dengan biskuit cokelat bulat gelap yang dihias dengan pola dan nama merek \"OREO\" di permukaan atas. Lapisan tengahnya berisi krim beraroma vanila yang lembut dan manis, menciptakan kombinasi renyah dan creamy saat dimakan.', 'https://thfvnext.bing.com/th/id/OIP.QIl3hNj7ZiwiOAV0-Ve9wQHaFU?w=209&h=180&c=7&r=0&o=7&cb=thfvnext&dpr=1.5&pid=1.7&rm=3', 1, 3, NULL),
(2, 'Cabe', NULL, 0.00, 3000.00, 99, 'pedas', '', 2, 1, NULL),
(3, 'Gula', NULL, 0.00, 12000.00, 10, 'Gulaku 500g', 'https://cdn0-production-images-kly.akamaized.net/TLqDBZPtEzqwx83Ms1Km5A6t-uc=/1280x720/smart/filters:quality(75):strip_icc():format(webp)/kly-media-production/medias/1498499/original/019958400_1486368597-Gula2.jpg', 3, 1, NULL),
(4, 'Pensil Mekanik', NULL, 0.00, 7000.00, 999, 'Untuk menulis', '', 2, 5, NULL),
(5, 'Indomie Goreng', 'Indofood', 2500.00, 3500.00, 50, 'Indomie Goreng Rasa Original', 'https://example.com/indomie.jpg', 1, 1, 1);

-- --------------------------------------------------------

--
-- Struktur dari tabel `master_ukuran`
--

CREATE TABLE `master_ukuran` (
  `id` int(11) NOT NULL,
  `nama_ukuran` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `master_ukuran`
--

INSERT INTO `master_ukuran` (`id`, `nama_ukuran`) VALUES
(1, 'Pcs'),
(2, 'Kg'),
(3, 'Gram'),
(4, 'Liter'),
(5, 'Box');

-- --------------------------------------------------------

--
-- Struktur dari tabel `master_user`
--

CREATE TABLE `master_user` (
  `id` int(50) NOT NULL,
  `username` varchar(50) NOT NULL,
  `kata_sandi` varchar(255) NOT NULL,
  `nama_lengkap` varchar(100) NOT NULL,
  `no_telp` varchar(20) DEFAULT NULL,
  `alamat` text DEFAULT NULL,
  `role` enum('admin','customer') DEFAULT 'customer'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `master_user`
--

INSERT INTO `master_user` (`id`, `username`, `kata_sandi`, `nama_lengkap`, `no_telp`, `alamat`, `role`) VALUES
(1, 'dandy', '123', 'dandy', NULL, NULL, 'customer'),
(2, 'adminverly', 'verly123', 'verly admin', NULL, NULL, 'admin'),
(3, 'dandycs', 'dandy123', 'Dandy CS', NULL, NULL, 'customer'),
(4, 'ddandy', '1234', 'DANDY D', NULL, NULL, 'customer'),
(5, 'testuser', 'password123', 'Test User', NULL, NULL, 'customer');

-- --------------------------------------------------------

--
-- Struktur dari tabel `transaksi`
--

CREATE TABLE `transaksi` (
  `id` int(11) NOT NULL,
  `tanggal` datetime NOT NULL DEFAULT current_timestamp(),
  `id_user` int(50) NOT NULL,
  `total_pembayaran` decimal(15,2) NOT NULL DEFAULT 0.00,
  `status` enum('pending','diproses','dipacking','dikirim','selesai','dibatalkan') NOT NULL DEFAULT 'pending',
  `metode_bayar` varchar(20) NOT NULL DEFAULT 'transfer',
  `bukti_transfer` varchar(255) DEFAULT NULL,
  `status_bayar` varchar(20) NOT NULL DEFAULT 'terverifikasi',
  `metode_kirim` varchar(20) NOT NULL DEFAULT 'reguler',
  `ongkir` decimal(15,2) NOT NULL DEFAULT 0.00,
  `diskon` decimal(15,2) NOT NULL DEFAULT 0.00,
  `kode_voucher` varchar(50) DEFAULT NULL,
  `cancel_requested` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `master_pengiriman`
--

CREATE TABLE `master_pengiriman` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `kode` varchar(20) NOT NULL,
  `nama` varchar(50) NOT NULL,
  `biaya` decimal(15,2) NOT NULL DEFAULT 0.00,
  `estimasi` varchar(50) DEFAULT NULL,
  `aktif` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `kode` (`kode`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT INTO `master_pengiriman` (`id`, `kode`, `nama`, `biaya`, `estimasi`, `aktif`) VALUES
(1, 'instant', 'Kurir Instant', 20000.00, '1-3 jam', 1),
(2, 'sameday', 'Kurir Sameday', 15000.00, 'Hari ini', 1),
(3, 'reguler', 'Kurir Reguler', 9000.00, '2-4 hari', 1);

-- --------------------------------------------------------

--
-- Struktur dari tabel `master_diskon`
--

CREATE TABLE `master_diskon` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nama` varchar(100) NOT NULL,
  `tipe` varchar(10) NOT NULL DEFAULT 'auto',
  `kode` varchar(50) DEFAULT NULL,
  `jenis_potongan` varchar(10) NOT NULL DEFAULT 'nominal',
  `nilai` decimal(15,2) NOT NULL DEFAULT 0.00,
  `min_belanja` decimal(15,2) NOT NULL DEFAULT 0.00,
  `maks_potongan` decimal(15,2) NOT NULL DEFAULT 0.00,
  `aktif` tinyint(1) NOT NULL DEFAULT 1,
  `tanggal_mulai` date DEFAULT NULL,
  `tanggal_selesai` date DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT INTO `master_diskon` (`id`, `nama`, `tipe`, `kode`, `jenis_potongan`, `nilai`, `min_belanja`, `maks_potongan`, `aktif`) VALUES
(1, 'Diskon 10% Min. 50RB', 'auto', NULL, 'persen', 10.00, 50000.00, 20000.00, 1),
(2, 'Voucher HEMAT5K', 'voucher', 'HEMAT5K', 'nominal', 5000.00, 0.00, 0.00, 1),
(3, 'Voucher NEWBIE 15%', 'voucher', 'NEWBIE', 'persen', 15.00, 30000.00, 25000.00, 1);

--
-- Indexes for dumped tables
--

--
-- Indeks untuk tabel `detail_transaksi`
--
ALTER TABLE `detail_transaksi`
  ADD PRIMARY KEY (`id`);

--
-- Indeks untuk tabel `master_gudang`
--
ALTER TABLE `master_gudang`
  ADD PRIMARY KEY (`id`);

--
-- Indeks untuk tabel `master_kategori`
--
ALTER TABLE `master_kategori`
  ADD PRIMARY KEY (`id`);

--
-- Indeks untuk tabel `master_product`
--
ALTER TABLE `master_product`
  ADD PRIMARY KEY (`id`);

--
-- Indeks untuk tabel `master_ukuran`
--
ALTER TABLE `master_ukuran`
  ADD PRIMARY KEY (`id`);

--
-- Indeks untuk tabel `master_user`
--
ALTER TABLE `master_user`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- Indeks untuk tabel `transaksi`
--
ALTER TABLE `transaksi`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT untuk tabel yang dibuang
--

--
-- AUTO_INCREMENT untuk tabel `detail_transaksi`
--
ALTER TABLE `detail_transaksi`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT untuk tabel `master_gudang`
--
ALTER TABLE `master_gudang`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT untuk tabel `master_kategori`
--
ALTER TABLE `master_kategori`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT untuk tabel `master_product`
--
ALTER TABLE `master_product`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT untuk tabel `master_ukuran`
--
ALTER TABLE `master_ukuran`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT untuk tabel `transaksi`
--
ALTER TABLE `transaksi`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;