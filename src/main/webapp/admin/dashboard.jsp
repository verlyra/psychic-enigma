<%@page import="jdbc.koneksi"%>
<%@page import="jdbc.DbInit"%>
<%@page import="java.sql.*"%>
<%@page import="java.util.*"%>
<%@page import="java.time.LocalDate"%>
<%@page import="java.time.format.DateTimeFormatter"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    if(session.getAttribute("user_id") == null || !"admin".equals(session.getAttribute("role"))) {
        response.sendRedirect("login.jsp");
        return;
    }

    int totalProducts = 0, totalUsers = 0, totalGudang = 0, totalKategori = 0, totalUkuran = 0;
    double totalRevenue = 0;
    int totalOrders = 0, perluVerifikasi = 0, mintaBatal = 0, pendingProcess = 0;

    // status: pending, diproses, dipacking, dikirim, selesai, dibatalkan
    final String[] ST = {"pending","diproses","dipacking","dikirim","selesai","dibatalkan"};
    int[] statusCounts = new int[ST.length];

    // 7 hari terakhir
    LocalDate today = LocalDate.now();
    LocalDate start7 = today.minusDays(6);
    DateTimeFormatter fmtLabel = DateTimeFormatter.ofPattern("dd/MM");
    List<String> revLabels = new ArrayList<>();
    List<Double> revData   = new ArrayList<>();

    List<String> topNames = new ArrayList<>();
    List<Integer> topQty  = new ArrayList<>();

    try {
        koneksi k = new koneksi();
        Connection conn = k.bukaKoneksi();
        if (conn != null) {
            DbInit.ensureSchema(conn);
            Statement stmt = conn.createStatement();

            ResultSet rs1 = stmt.executeQuery("SELECT COUNT(*) FROM master_product"); if(rs1.next()) totalProducts = rs1.getInt(1); rs1.close();
            ResultSet rs2 = stmt.executeQuery("SELECT COUNT(*) FROM master_user");    if(rs2.next()) totalUsers = rs2.getInt(1);    rs2.close();
            ResultSet rs3 = stmt.executeQuery("SELECT COUNT(*) FROM master_gudang");  if(rs3.next()) totalGudang = rs3.getInt(1);   rs3.close();
            ResultSet rs4 = stmt.executeQuery("SELECT COUNT(*) FROM master_kategori");if(rs4.next()) totalKategori = rs4.getInt(1); rs4.close();
            ResultSet rs5 = stmt.executeQuery("SELECT COUNT(*) FROM master_ukuran");  if(rs5.next()) totalUkuran = rs5.getInt(1);   rs5.close();

            // Omzet & jumlah order selesai
            ResultSet rsR = stmt.executeQuery(
                "SELECT COALESCE(SUM(d.subtotal),0) rev, COUNT(DISTINCT t.id) ord " +
                "FROM transaksi t LEFT JOIN detail_transaksi d ON t.id=d.id_transaksi WHERE t.status='selesai'");
            if (rsR.next()) { totalRevenue = rsR.getDouble("rev"); totalOrders = rsR.getInt("ord"); }
            rsR.close();

            ResultSet rsV = stmt.executeQuery("SELECT COUNT(*) FROM transaksi WHERE metode_bayar='transfer' AND status_bayar='menunggu' AND bukti_transfer IS NOT NULL");
            if (rsV.next()) perluVerifikasi = rsV.getInt(1); rsV.close();
            ResultSet rsB = stmt.executeQuery("SELECT COUNT(*) FROM transaksi WHERE cancel_requested=1"); if (rsB.next()) mintaBatal = rsB.getInt(1); rsB.close();
            ResultSet rsP = stmt.executeQuery("SELECT COUNT(*) FROM transaksi WHERE status_bayar='terverifikasi' AND status IN ('pending','diproses','dipacking','dikirim')");
            if (rsP.next()) pendingProcess = rsP.getInt(1); rsP.close();

            // Status distribution
            ResultSet rsS = stmt.executeQuery("SELECT status, COUNT(*) c FROM transaksi GROUP BY status");
            Map<String,Integer> smap = new HashMap<>();
            while (rsS.next()) smap.put(rsS.getString("status"), rsS.getInt("c"));
            rsS.close();
            for (int i=0;i<ST.length;i++) statusCounts[i] = smap.getOrDefault(ST[i], 0);
            stmt.close();

            // Omzet 7 hari terakhir
            PreparedStatement psW = conn.prepareStatement(
                "SELECT DATE(t.tanggal) hari, COALESCE(SUM(d.subtotal),0) rev " +
                "FROM transaksi t LEFT JOIN detail_transaksi d ON t.id=d.id_transaksi " +
                "WHERE t.status='selesai' AND DATE(t.tanggal) >= ? GROUP BY DATE(t.tanggal)");
            psW.setString(1, start7.toString());
            ResultSet rsW = psW.executeQuery();
            Map<String,Double> revMap = new HashMap<>();
            while (rsW.next()) revMap.put(rsW.getString("hari"), rsW.getDouble("rev"));
            rsW.close(); psW.close();
            for (int i=0;i<7;i++) {
                LocalDate d = start7.plusDays(i);
                revLabels.add(d.format(fmtLabel));
                revData.add(revMap.getOrDefault(d.toString(), 0.0));
            }

            // Top 5 produk terlaris (selesai)
            PreparedStatement psT = conn.prepareStatement(
                "SELECT p.nama_produk, COALESCE(SUM(d.qty),0) q " +
                "FROM detail_transaksi d JOIN master_product p ON d.id_product=p.id " +
                "JOIN transaksi t ON d.id_transaksi=t.id WHERE t.status='selesai' " +
                "GROUP BY p.id, p.nama_produk ORDER BY q DESC LIMIT 5");
            ResultSet rsT = psT.executeQuery();
            while (rsT.next()) { topNames.add(rsT.getString("nama_produk")); topQty.add(rsT.getInt("q")); }
            rsT.close(); psT.close();

            conn.close();
        }
    } catch(Exception e) { }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Dashboard - VEND.IO Admin</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;700;900&display=swap" rel="stylesheet">
    <style>
        body { font-family: 'Inter', sans-serif; background-color: #e5e7eb; }
        .brutal-shadow { box-shadow: 8px 8px 0px 0px rgba(0,0,0,1); }
    </style>
</head>
<body class="flex min-h-screen">
    <!-- Sidebar -->
    <aside class="w-64 bg-black text-white flex flex-col justify-between py-6 flex-shrink-0">
        <div>
            <div class="px-6 flex items-center gap-3 mb-6">
                <div class="bg-[#FACC15] p-2">
                    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="black" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="9" cy="21" r="1"></circle><circle cx="20" cy="21" r="1"></circle><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"></path>
                    </svg>
                </div>
                <h1 class="text-2xl font-[900] italic tracking-tighter">VEND.IO</h1>
            </div>
            <div class="border-t-[3px] border-white mx-6 mb-8"></div>
            <nav class="flex flex-col space-y-2">
                <a href="dashboard.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase bg-[#FACC15] text-black">Dashboard</a>
                <a href="pesanan.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">PESANAN</a>
                <a href="pengiriman.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">PENGIRIMAN</a>
                <a href="diskon.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">DISKON & PROMO</a>
                <a href="products.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">INVENTORY</a>
                <a href="kategori.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">MASTER KATEGORI</a>
                <a href="ukuran.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">MASTER UKURAN</a>
                <a href="users.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">MASTER USER</a>
                <a href="gudang.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">MASTER GUDANG</a>
                <a href="laporan.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">LAPORAN PENJUALAN</a>
            </nav>
        </div>
        <div class="px-6 mt-8">
            <div class="border-t-[3px] border-white mb-4"></div>
            <p class="text-xs font-bold text-gray-400 mb-1 tracking-widest uppercase">STAFF</p>
            <p class="font-[900] tracking-wider uppercase mb-2 truncate"><%= session.getAttribute("nama_lengkap") %></p>
            <a href="logout.jsp" class="font-[900] text-red-500 hover:text-red-400 text-sm tracking-wider uppercase">LOG OUT</a>
        </div>
    </aside>

    <!-- Main Content -->
    <main class="flex-1 p-10 flex flex-col relative overflow-y-auto">
        <h2 class="text-4xl font-[900] text-black tracking-tight uppercase mb-8">OVERVIEW</h2>

        <!-- KPI cards -->
        <div class="grid grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
            <div class="bg-white border-[4px] border-black p-6 brutal-shadow">
                <p class="font-[900] text-xs uppercase tracking-widest text-gray-400 m-0 mb-2">OMZET (SELESAI)</p>
                <p class="font-[900] text-2xl text-[#3498DB] drop-shadow-[3px_3px_0px_rgba(0,0,0,1)] m-0 leading-tight">Rp<%= String.format("%,.0f", totalRevenue) %></p>
            </div>
            <div class="bg-white border-[4px] border-black p-6 brutal-shadow">
                <p class="font-[900] text-xs uppercase tracking-widest text-gray-400 m-0 mb-2">ORDER SELESAI</p>
                <p class="font-[900] text-4xl text-[#4ADE80] drop-shadow-[3px_3px_0px_rgba(0,0,0,1)] m-0"><%= totalOrders %></p>
            </div>
            <a href="pesanan.jsp?filter=verifikasi" class="bg-white border-[4px] border-black p-6 brutal-shadow hover:bg-[#FACC15] transition-colors">
                <p class="font-[900] text-xs uppercase tracking-widest text-gray-400 m-0 mb-2">PERLU VERIFIKASI</p>
                <p class="font-[900] text-4xl text-[#F97316] drop-shadow-[3px_3px_0px_rgba(0,0,0,1)] m-0"><%= perluVerifikasi %></p>
            </a>
            <a href="pesanan.jsp?filter=batal" class="bg-white border-[4px] border-black p-6 brutal-shadow hover:bg-orange-200 transition-colors">
                <p class="font-[900] text-xs uppercase tracking-widest text-gray-400 m-0 mb-2">MINTA BATAL</p>
                <p class="font-[900] text-4xl text-[#EF4444] drop-shadow-[3px_3px_0px_rgba(0,0,0,1)] m-0"><%= mintaBatal %></p>
            </a>
        </div>

        <!-- Charts row -->
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
            <div class="lg:col-span-2 bg-black p-3 brutal-shadow">
                <div class="bg-white border-[4px] border-black p-6">
                    <h3 class="font-[900] text-xl uppercase tracking-tighter mb-4 m-0">OMZET 7 HARI TERAKHIR</h3>
                    <div style="height:280px;"><canvas id="revChart"></canvas></div>
                </div>
            </div>
            <div class="bg-black p-3 brutal-shadow">
                <div class="bg-white border-[4px] border-black p-6">
                    <h3 class="font-[900] text-xl uppercase tracking-tighter mb-4 m-0">STATUS PESANAN</h3>
                    <div style="height:280px;"><canvas id="statusChart"></canvas></div>
                </div>
            </div>
        </div>

        <!-- Top products + master counts -->
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
            <div class="lg:col-span-2 bg-black p-3 brutal-shadow">
                <div class="bg-white border-[4px] border-black p-6">
                    <h3 class="font-[900] text-xl uppercase tracking-tighter mb-4 m-0">TOP 5 PRODUK TERLARIS</h3>
                    <% if (topNames.isEmpty()) { %>
                    <p class="font-bold text-gray-400 text-sm m-0 py-8 text-center">Belum ada produk terjual (selesai).</p>
                    <% } else { %>
                    <div style="height:260px;"><canvas id="topChart"></canvas></div>
                    <% } %>
                </div>
            </div>
            <div class="bg-black p-3 brutal-shadow">
                <div class="bg-white border-[4px] border-black p-6 h-full">
                    <h3 class="font-[900] text-xl uppercase tracking-tighter mb-4 m-0">DATA MASTER</h3>
                    <div class="space-y-3">
                        <div class="flex justify-between border-b-[2px] border-gray-100 pb-2"><span class="font-bold text-gray-500 uppercase text-sm">Produk</span><span class="font-[900] text-lg"><%= totalProducts %></span></div>
                        <div class="flex justify-between border-b-[2px] border-gray-100 pb-2"><span class="font-bold text-gray-500 uppercase text-sm">Users</span><span class="font-[900] text-lg"><%= totalUsers %></span></div>
                        <div class="flex justify-between border-b-[2px] border-gray-100 pb-2"><span class="font-bold text-gray-500 uppercase text-sm">Gudang</span><span class="font-[900] text-lg"><%= totalGudang %></span></div>
                        <div class="flex justify-between border-b-[2px] border-gray-100 pb-2"><span class="font-bold text-gray-500 uppercase text-sm">Kategori</span><span class="font-[900] text-lg"><%= totalKategori %></span></div>
                        <div class="flex justify-between"><span class="font-bold text-gray-500 uppercase text-sm">Ukuran</span><span class="font-[900] text-lg"><%= totalUkuran %></span></div>
                        <div class="flex justify-between bg-[#FACC15] border-[2px] border-black px-3 py-2 mt-2"><span class="font-[900] uppercase text-sm">Sedang Diproses</span><span class="font-[900] text-lg"><%= pendingProcess %></span></div>
                    </div>
                </div>
            </div>
        </div>

        <p class="font-bold text-gray-400 text-sm text-right">Developed by Dandy & Verly</p>
    </main>

    <script>
        // Omzet 7 hari
        new Chart(document.getElementById('revChart'), {
            type: 'bar',
            data: {
                labels: [<% for (int i=0;i<revLabels.size();i++){ %>"<%= revLabels.get(i) %>"<%= i<revLabels.size()-1?",":"" %><% } %>],
                datasets: [{ label: 'Omzet', data: [<% for (int i=0;i<revData.size();i++){ %><%= revData.get(i) %><%= i<revData.size()-1?",":"" %><% } %>], backgroundColor: '#3498DB', borderColor: '#000', borderWidth: 2 }]
            },
            options: { responsive: true, maintainAspectRatio: false,
                plugins: { legend: { display: false } },
                scales: { y: { beginAtZero: true, ticks: { callback: function(v){ return 'Rp' + v.toLocaleString('id-ID'); } } } } }
        });

        // Status pesanan
        new Chart(document.getElementById('statusChart'), {
            type: 'doughnut',
            data: {
                labels: ['Pending','Diproses','Dipacking','Dikirim','Selesai','Dibatalkan'],
                datasets: [{ data: [<%= statusCounts[0] %>,<%= statusCounts[1] %>,<%= statusCounts[2] %>,<%= statusCounts[3] %>,<%= statusCounts[4] %>,<%= statusCounts[5] %>],
                    backgroundColor: ['#D1D5DB','#3498DB','#A855F7','#FB923C','#4ADE80','#EF4444'], borderColor: '#000', borderWidth: 2 }]
            },
            options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { position: 'bottom', labels: { font: { weight: '900' }, boxWidth: 14 } } } }
        });

        <% if (!topNames.isEmpty()) { %>
        // Top produk
        new Chart(document.getElementById('topChart'), {
            type: 'bar',
            data: {
                labels: [<% for (int i=0;i<topNames.size();i++){ %>"<%= topNames.get(i).replace("\"","\\\"") %>"<%= i<topNames.size()-1?",":"" %><% } %>],
                datasets: [{ label: 'Qty Terjual', data: [<% for (int i=0;i<topQty.size();i++){ %><%= topQty.get(i) %><%= i<topQty.size()-1?",":"" %><% } %>], backgroundColor: '#FACC15', borderColor: '#000', borderWidth: 2 }]
            },
            options: { indexAxis: 'y', responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } }, scales: { x: { beginAtZero: true } } }
        });
        <% } %>
    </script>
</body>
</html>
