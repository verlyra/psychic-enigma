-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: May 20, 2026 at 04:03 AM
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
-- Table structure for table `master_gudang`
--

CREATE TABLE `master_gudang` (
  `id` int(11) NOT NULL,
  `nama_gudang` varchar(100) NOT NULL,
  `lokasi` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `master_gudang`
--

INSERT INTO `master_gudang` (`id`, `nama_gudang`, `lokasi`) VALUES
(1, 'CBD', 'CILEDUG'),
(2, 'BINTARO', 'BINTARO SEKTOR 3'),
(3, 'SMS', 'Kota tangerang');

-- --------------------------------------------------------

--
-- Table structure for table `master_kategori`
--

CREATE TABLE `master_kategori` (
  `id` int(11) NOT NULL,
  `nama_kategori` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `master_kategori`
--

INSERT INTO `master_kategori` (`id`, `nama_kategori`) VALUES
(1, 'FOOD'),
(2, 'DRINK'),
(3, 'SNACK'),
(4, 'OTHER'),
(5, 'STATIONARY');

-- --------------------------------------------------------

--
-- Table structure for table `master_product`
--

CREATE TABLE `master_product` (
  `id` int(11) NOT NULL,
  `nama_produk` varchar(100) NOT NULL,
  `harga` decimal(10,2) NOT NULL,
  `stok` int(11) NOT NULL DEFAULT 0,
  `deskripsi` text DEFAULT NULL,
  `image_url` text DEFAULT NULL,
  `id_gudang` int(11) DEFAULT NULL,
  `id_kategori` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `master_product`
--

INSERT INTO `master_product` (`id`, `nama_produk`, `harga`, `stok`, `deskripsi`, `image_url`, `id_gudang`, `id_kategori`) VALUES
(1, 'Oreo', 10000.00, 1000, 'Oreo memiliki penampilan yang khas, dengan biskuit cokelat bulat gelap yang dihias dengan pola dan nama merek \"OREO\" di permukaan atas. Lapisan tengahnya berisi krim beraroma vanila yang lembut dan manis, menciptakan kombinasi renyah dan creamy saat dimakan.', 'https://thfvnext.bing.com/th/id/OIP.QIl3hNj7ZiwiOAV0-Ve9wQHaFU?w=209&h=180&c=7&r=0&o=7&cb=thfvnext&dpr=1.5&pid=1.7&rm=3', 1, 3),
(2, 'Cabe', 3000.00, 99, 'pedas', '', 2, 1),
(3, 'Gula', 12000.00, 10, 'Gulaku 500g', 'https://cdn0-production-images-kly.akamaized.net/TLqDBZPtEzqwx83Ms1Km5A6t-uc=/1280x720/smart/filters:quality(75):strip_icc():format(webp)/kly-media-production/medias/1498499/original/019958400_1486368597-Gula2.jpg', 3, 1),
(4, 'Pensil Mekanik', 7000.00, 999, 'Untuk menulis', '', 2, 5);

-- --------------------------------------------------------

--
-- Table structure for table `master_user`
--

CREATE TABLE `master_user` (
  `id` int(50) NOT NULL,
  `username` varchar(50) NOT NULL,
  `kata_sandi` varchar(255) NOT NULL,
  `nama_lengkap` varchar(100) NOT NULL,
  `role` enum('admin','customer') DEFAULT 'customer'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `master_user`
--

INSERT INTO `master_user` (`id`, `username`, `kata_sandi`, `nama_lengkap`, `role`) VALUES
(1, 'dandy', '123', 'dandy', 'customer'),
(2, 'adminverly', 'verly123', 'verly admin', 'admin'),
(3, 'dandycs', 'dandy123', 'Dandy CS', 'customer'),
(4, 'ddandy', '1234', 'DANDY D', 'customer');

--
-- Indexes for dumped tables
--

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
-- Indexes for table `master_product`
--
ALTER TABLE `master_product`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `master_user`
--
ALTER TABLE `master_user`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `master_gudang`
--
ALTER TABLE `master_gudang`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `master_kategori`
--
ALTER TABLE `master_kategori`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `master_product`
--
ALTER TABLE `master_product`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
