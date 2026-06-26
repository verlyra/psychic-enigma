-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jun 26, 2026 at 06:03 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

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
-- Table structure for table `detail_transaksi`
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

--
-- Dumping data for table `detail_transaksi`
--

INSERT INTO `detail_transaksi` (`id`, `id_transaksi`, `id_product`, `qty`, `harga_beli`, `harga_jual`, `subtotal`) VALUES
(1, 1, 5, 5, 2500.00, 3500.00, 17500.00),
(2, 2, 5, 1, 2500.00, 3500.00, 3500.00),
(3, 2, 4, 2, 0.00, 7000.00, 14000.00),
(4, 2, 3, 2, 0.00, 12000.00, 24000.00),
(5, 2, 2, 2, 0.00, 3000.00, 6000.00),
(6, 2, 1, 2, 0.00, 10000.00, 20000.00),
(7, 3, 5, 1, 2500.00, 3500.00, 3500.00),
(8, 4, 4, 1, 0.00, 7000.00, 7000.00),
(9, 5, 3, 2, 0.00, 12000.00, 24000.00),
(10, 6, 3, 6, 0.00, 12000.00, 72000.00),
(11, 7, 3, 2, 0.00, 12000.00, 24000.00),
(12, 8, 7, 2, 5000.00, 15000.00, 30000.00),
(13, 9, 7, 1, 5000.00, 15000.00, 15000.00),
(14, 10, 8, 1, 3000.00, 5000.00, 5000.00),
(15, 11, 8, 1, 3000.00, 5000.00, 5000.00),
(16, 11, 3, 1, 5000.00, 12000.00, 12000.00),
(17, 11, 6, 4, 2500.00, 3500.00, 14000.00),
(18, 11, 5, 1, 2500.00, 3500.00, 3500.00),
(19, 12, 3, 1, 5000.00, 12000.00, 12000.00),
(20, 12, 8, 1, 3000.00, 5000.00, 5000.00),
(21, 13, 3, 1, 5000.00, 12000.00, 12000.00),
(22, 14, 6, 1, 2500.00, 3500.00, 3500.00),
(23, 15, 8, 1, 3000.00, 5000.00, 5000.00),
(24, 16, 6, 1, 2500.00, 3500.00, 3500.00),
(25, 17, 3, 20, 5000.00, 12000.00, 240000.00),
(26, 18, 3, 1, 5000.00, 12000.00, 12000.00),
(27, 18, 8, 14, 3000.00, 5000.00, 70000.00),
(28, 19, 8, 1, 3000.00, 5000.00, 5000.00),
(29, 20, 8, 1, 3000.00, 5000.00, 5000.00),
(30, 20, 5, 4, 2500.00, 3500.00, 14000.00),
(31, 20, 3, 2, 5000.00, 12000.00, 24000.00),
(32, 20, 2, 2, 500.00, 5000.00, 10000.00),
(33, 21, 8, 5, 3000.00, 5000.00, 25000.00),
(34, 22, 8, 8, 3000.00, 5000.00, 40000.00);

-- --------------------------------------------------------

--
-- Table structure for table `master_diskon`
--

CREATE TABLE `master_diskon` (
  `id` int(11) NOT NULL,
  `nama` varchar(100) NOT NULL,
  `tipe` varchar(10) NOT NULL DEFAULT 'auto',
  `kode` varchar(50) DEFAULT NULL,
  `jenis_potongan` varchar(10) NOT NULL DEFAULT 'nominal',
  `nilai` decimal(15,2) NOT NULL DEFAULT 0.00,
  `min_belanja` decimal(15,2) NOT NULL DEFAULT 0.00,
  `maks_potongan` decimal(15,2) NOT NULL DEFAULT 0.00,
  `aktif` tinyint(1) NOT NULL DEFAULT 1,
  `tanggal_mulai` date DEFAULT NULL,
  `tanggal_selesai` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `master_diskon`
--

INSERT INTO `master_diskon` (`id`, `nama`, `tipe`, `kode`, `jenis_potongan`, `nilai`, `min_belanja`, `maks_potongan`, `aktif`, `tanggal_mulai`, `tanggal_selesai`) VALUES
(1, 'Diskon 10% Min. 50RB', 'auto', NULL, 'persen', 10.00, 50000.00, 20000.00, 1, NULL, NULL),
(2, 'Voucher HEMAT5K', 'voucher', 'HEMAT5K', 'nominal', 5000.00, 10000.00, 0.00, 1, NULL, NULL),
(3, 'Voucher NEWBIE 15%', 'voucher', 'NEWBIE', 'persen', 15.00, 30000.00, 25000.00, 1, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `master_gudang`
--

CREATE TABLE `master_gudang` (
  `id` int(11) NOT NULL,
  `nama_gudang` varchar(100) NOT NULL,
  `lokasi` varchar(255) NOT NULL,
  `nama_pic` varchar(100) DEFAULT NULL,
  `no_telp` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `master_gudang`
--

INSERT INTO `master_gudang` (`id`, `nama_gudang`, `lokasi`, `nama_pic`, `no_telp`) VALUES
(1, 'CBD', 'CILEDUG', NULL, NULL),
(2, 'BINTARO', 'BINTARO SEKTOR 3', NULL, NULL),
(3, 'SMS', 'Kota tangerang', NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `master_kategori`
--

CREATE TABLE `master_kategori` (
  `id` int(11) NOT NULL,
  `nama_kategori` varchar(255) NOT NULL,
  `deskripsi` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `master_kategori`
--

INSERT INTO `master_kategori` (`id`, `nama_kategori`, `deskripsi`) VALUES
(1, 'FOOD', 'MAKANAN'),
(2, 'DRINK', NULL),
(3, 'SNACK', NULL),
(4, 'OTHER', NULL),
(5, 'STATIONARY', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `master_pengiriman`
--

CREATE TABLE `master_pengiriman` (
  `id` int(11) NOT NULL,
  `kode` varchar(20) NOT NULL,
  `nama` varchar(50) NOT NULL,
  `biaya` decimal(15,2) NOT NULL DEFAULT 0.00,
  `estimasi` varchar(50) DEFAULT NULL,
  `aktif` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `master_pengiriman`
--

INSERT INTO `master_pengiriman` (`id`, `kode`, `nama`, `biaya`, `estimasi`, `aktif`) VALUES
(1, 'instant', 'Kurir Instant', 20000.00, '1-3 jam', 1),
(2, 'sameday', 'Kurir Sameday', 15000.00, 'Hari ini', 1),
(3, 'reguler', 'Kurir Reguler', 9000.00, '2-4 hari', 1);

-- --------------------------------------------------------

--
-- Table structure for table `master_product`
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
-- Dumping data for table `master_product`
--

INSERT INTO `master_product` (`id`, `nama_produk`, `merk`, `harga_beli`, `harga_jual`, `stok`, `deskripsi`, `image_url`, `id_gudang`, `id_kategori`, `id_ukuran`) VALUES
(2, 'Cabe', 'Cabeku', 500.00, 5000.00, 95, 'Cabe merah pedas', 'https://4.bp.blogspot.com/-FfCb3c4VlNg/V8wfrLUKhTI/AAAAAAAAE2w/OcyAN1RzKTg_PzePz6HFiD7f59ZkGkhQwCLcB/s1600/chili-1128547_1920.jpg', 2, 1, 3),
(3, 'Gula', 'Gulaku', 5000.00, 12000.00, 90, 'GULAKU Gula Tebu Premium 1kg hadir dalam kemasan pillow pack. Gulaku Premium dihasilkan dari tebu segar berkualitas yang tumbuh di perkebunan Lampung. Gula tebu diproses dengan standar mutu yang tinggi sehingga menghasilkan gula yang murni, manis, bersih, dan alami. Gula tebu asli Indonesia ini akan menjadi pemanis yang pas bagi semua makanan dan minuman Anda.', 'https://cdn0-production-images-kly.akamaized.net/TLqDBZPtEzqwx83Ms1Km5A6t-uc=/1280x720/smart/filters:quality(75):strip_icc():format(webp)/kly-media-production/medias/1498499/original/019958400_1486368597-Gula2.jpg', 3, 1, 2),
(5, 'Indomie Goreng', 'Indofood', 2500.00, 3500.00, 38, 'Indomie Goreng Rasa Original', 'https://foodbybox.com/wp-content/uploads/2023/03/Mie-Goreng-Special-1-pcs-scaled.jpg', 1, 1, 1),
(6, 'Indomie Soto', 'Indofood', 2500.00, 3500.00, 37, 'Indomie soto enak', 'https://www.static-src.com/wcsstore/Indraprastha/images/catalog/full/98/MTA-44288071/indomie_indomie_rasa_soto_70_g_full01_qdkswbo0.jpg', 1, 1, 1),
(7, 'Ayam Paha', 'Boiler', 5000.00, 15000.00, 90, 'Potongan ayam paha 500g', 'https://tse2.mm.bing.net/th/id/OIP.5vLUzlue1hcy1XGYPZkmDQAAAA?r=0&rs=1&pid=ImgDetMain&o=7&rm=3', 1, 1, 3),
(8, 'Teh', 'Sosro', 3000.00, 5000.00, 96, 'Teh Sosro Segar', 'data:image/webp;base64,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', 3, 2, 1);

-- --------------------------------------------------------

--
-- Table structure for table `master_ukuran`
--

CREATE TABLE `master_ukuran` (
  `id` int(11) NOT NULL,
  `nama_ukuran` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `master_ukuran`
--

INSERT INTO `master_ukuran` (`id`, `nama_ukuran`) VALUES
(1, 'Pcs'),
(2, 'Kg'),
(3, 'Gram'),
(4, 'Liter'),
(5, 'Box');

-- --------------------------------------------------------

--
-- Table structure for table `master_user`
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
-- Dumping data for table `master_user`
--

INSERT INTO `master_user` (`id`, `username`, `kata_sandi`, `nama_lengkap`, `no_telp`, `alamat`, `role`) VALUES
(1, 'dandy', '123', 'dandy', NULL, NULL, 'admin'),
(2, 'adminverly', 'verly123', 'verly admin', NULL, NULL, 'admin'),
(3, 'dandycs', 'dandy123', 'Dandy CS', NULL, NULL, 'customer'),
(4, 'ddandy', '1234', 'DANDY D', NULL, NULL, 'customer'),
(5, 'testuser', 'password123', 'Test User', NULL, NULL, 'customer'),
(6, 'cust', '123', 'Customer', '08123456789', 'JLN JLN', 'customer'),
(7, '626', '123', 'ver', '081', 'jl.Jalan', 'customer');

-- --------------------------------------------------------

--
-- Table structure for table `transaksi`
--

CREATE TABLE `transaksi` (
  `id` int(11) NOT NULL,
  `tanggal` datetime NOT NULL DEFAULT current_timestamp(),
  `id_user` int(50) NOT NULL,
  `total_pembayaran` decimal(15,2) NOT NULL DEFAULT 0.00,
  `status` varchar(20) NOT NULL DEFAULT 'pending',
  `metode_bayar` varchar(20) NOT NULL DEFAULT 'transfer',
  `bukti_transfer` varchar(255) DEFAULT NULL,
  `status_bayar` varchar(20) NOT NULL DEFAULT 'terverifikasi',
  `metode_kirim` varchar(20) NOT NULL DEFAULT 'reguler',
  `ongkir` decimal(15,2) NOT NULL DEFAULT 0.00,
  `diskon` decimal(15,2) NOT NULL DEFAULT 0.00,
  `kode_voucher` varchar(50) DEFAULT NULL,
  `cancel_requested` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `transaksi`
--

INSERT INTO `transaksi` (`id`, `tanggal`, `id_user`, `total_pembayaran`, `status`, `metode_bayar`, `bukti_transfer`, `status_bayar`, `metode_kirim`, `ongkir`, `diskon`, `kode_voucher`, `cancel_requested`) VALUES
(1, '2026-06-24 08:50:39', 1, 17500.00, 'selesai', 'transfer', NULL, 'terverifikasi', 'reguler', 0.00, 0.00, NULL, 0),
(2, '2026-06-24 09:32:34', 1, 67500.00, 'selesai', 'transfer', NULL, 'terverifikasi', 'reguler', 0.00, 0.00, NULL, 0),
(3, '2026-06-24 09:38:56', 1, 3500.00, 'selesai', 'transfer', NULL, 'terverifikasi', 'reguler', 0.00, 0.00, NULL, 0),
(4, '2026-06-24 09:46:20', 1, 7000.00, 'selesai', 'transfer', NULL, 'terverifikasi', 'reguler', 0.00, 0.00, NULL, 0),
(5, '2026-06-24 10:14:24', 1, 24000.00, 'selesai', 'transfer', NULL, 'terverifikasi', 'reguler', 0.00, 0.00, NULL, 0),
(6, '2026-06-24 10:14:52', 1, 72000.00, 'selesai', 'transfer', NULL, 'terverifikasi', 'reguler', 0.00, 0.00, NULL, 0),
(7, '2026-06-24 10:18:30', 1, 24000.00, 'selesai', 'transfer', NULL, 'terverifikasi', 'reguler', 0.00, 0.00, NULL, 0),
(8, '2026-06-24 11:52:55', 6, 30000.00, 'selesai', 'transfer', NULL, 'terverifikasi', 'reguler', 0.00, 0.00, NULL, 0),
(9, '2026-06-24 12:01:45', 2, 15000.00, 'selesai', 'transfer', NULL, 'terverifikasi', 'reguler', 0.00, 0.00, NULL, 0),
(10, '2026-06-24 12:04:31', 2, 5000.00, 'selesai', 'transfer', NULL, 'terverifikasi', 'reguler', 0.00, 0.00, NULL, 0),
(11, '2026-06-26 08:20:09', 1, 38500.00, 'selesai', 'transfer', 'uploads/bukti/bukti_11_1782436822513.png', 'terverifikasi', 'reguler', 9000.00, 5000.00, 'Hemat5k', 0),
(12, '2026-06-26 08:34:59', 1, 37000.00, 'dibatalkan', 'ewallet', NULL, 'terverifikasi', 'instant', 20000.00, 0.00, NULL, 0),
(13, '2026-06-26 08:52:30', 1, 32000.00, 'pending', 'transfer', NULL, 'menunggu', 'instant', 20000.00, 0.00, NULL, 0),
(14, '2026-06-26 08:55:44', 1, 12500.00, 'pending', 'ewallet', NULL, 'menunggu', 'reguler', 9000.00, 0.00, NULL, 0),
(15, '2026-06-26 09:01:56', 1, 25000.00, 'pending', 'ewallet', NULL, 'menunggu', 'instant', 20000.00, 0.00, NULL, 0),
(16, '2026-06-26 09:09:23', 1, 23500.00, 'selesai', 'ewallet', NULL, 'terverifikasi', 'instant', 20000.00, 0.00, NULL, 0),
(17, '2026-06-26 09:13:16', 1, 204000.00, 'selesai', 'transfer', 'uploads/bukti/bukti_17_1782440030053.png', 'terverifikasi', 'reguler', 9000.00, 45000.00, 'newbie', 0),
(18, '2026-06-26 09:16:13', 1, 88800.00, 'dibatalkan', 'transfer', 'uploads/bukti/bukti_18_1782440229603.png', 'ditolak', 'instant', 20000.00, 13200.00, 'hemat5k', 0),
(19, '2026-06-26 09:22:17', 1, 14000.00, 'dibatalkan', 'transfer', 'uploads/bukti/bukti_19_1782440547983.png', 'ditolak', 'reguler', 9000.00, 0.00, NULL, 0),
(20, '2026-06-26 09:29:39', 7, 62700.00, 'selesai', 'transfer', 'uploads/bukti/bukti_20_1782441033284.png', 'terverifikasi', 'instant', 20000.00, 10300.00, 'hemat5k', 0),
(21, '2026-06-26 09:40:56', 1, 29000.00, 'dibatalkan', 'ewallet', NULL, 'terverifikasi', 'reguler', 9000.00, 5000.00, 'hemat5k', 0),
(22, '2026-06-26 09:45:32', 7, 60000.00, 'dibatalkan', 'transfer', 'uploads/bukti/bukti_22_1782441951932.png', 'ditolak', 'instant', 20000.00, 0.00, NULL, 0);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `detail_transaksi`
--
ALTER TABLE `detail_transaksi`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `master_diskon`
--
ALTER TABLE `master_diskon`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `master_gudang`
--
ALTER TABLE `master_gudang`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `master_kategori`
--
ALTER TABLE `master_kategori`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `master_pengiriman`
--
ALTER TABLE `master_pengiriman`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `kode` (`kode`);

--
-- Indexes for table `master_product`
--
ALTER TABLE `master_product`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `master_ukuran`
--
ALTER TABLE `master_ukuran`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `master_user`
--
ALTER TABLE `master_user`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- Indexes for table `transaksi`
--
ALTER TABLE `transaksi`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `detail_transaksi`
--
ALTER TABLE `detail_transaksi`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=35;

--
-- AUTO_INCREMENT for table `master_diskon`
--
ALTER TABLE `master_diskon`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `master_gudang`
--
ALTER TABLE `master_gudang`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `master_kategori`
--
ALTER TABLE `master_kategori`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `master_pengiriman`
--
ALTER TABLE `master_pengiriman`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `master_product`
--
ALTER TABLE `master_product`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `master_ukuran`
--
ALTER TABLE `master_ukuran`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `transaksi`
--
ALTER TABLE `transaksi`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
