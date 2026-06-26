<%@page import="jdbc.koneksi" %>
    <%@page import="java.sql.*" %>
        <%@page import="java.util.*" %>
            <%@page import="java.time.LocalDate" %>
                <%@page contentType="text/html" pageEncoding="UTF-8" %>
                    <% if(session.getAttribute("user_id")==null || !"admin".equals(session.getAttribute("role"))) {
                        response.sendRedirect("login.jsp"); return; } LocalDate today=LocalDate.now(); LocalDate
                        firstOfMonth=today.withDayOfMonth(1); String dateFrom=request.getParameter("date_from"); String
                        dateTo=request.getParameter("date_to"); if (dateFrom==null || dateFrom.isEmpty())
                        dateFrom=firstOfMonth.toString(); if (dateTo==null || dateTo.isEmpty()) dateTo=today.toString();
                        int totalOrders=0; double totalRevenue=0; double totalCost=0; int totalItemsSold=0;
                        List<Map<String, Object>> transactions = new ArrayList<>();
                        List<String> chartLabels = new ArrayList<>();
                        List<Double> chartOmzet = new ArrayList<>();
                        List<Double> chartLaba = new ArrayList<>();

                            try {
                            koneksi k = new koneksi();
                            Connection conn = k.bukaKoneksi();

                            PreparedStatement psSummary = conn.prepareStatement(
                            "SELECT COUNT(DISTINCT t.id) AS total_orders, " +
                            "COALESCE(SUM(d.subtotal), 0) AS total_revenue, " +
                            "COALESCE(SUM(d.harga_beli * d.qty), 0) AS total_cost, " +
                            "COALESCE(SUM(d.qty), 0) AS total_items " +
                            "FROM transaksi t LEFT JOIN detail_transaksi d ON t.id = d.id_transaksi " +
                            "WHERE t.status = 'selesai' AND DATE(t.tanggal) BETWEEN ? AND ?"
                            );
                            psSummary.setString(1, dateFrom);
                            psSummary.setString(2, dateTo);
                            ResultSet rsSummary = psSummary.executeQuery();
                            if (rsSummary.next()) {
                            totalOrders = rsSummary.getInt("total_orders");
                            totalRevenue = rsSummary.getDouble("total_revenue");
                            totalCost = rsSummary.getDouble("total_cost");
                            totalItemsSold = rsSummary.getInt("total_items");
                            }
                            rsSummary.close(); psSummary.close();

                            PreparedStatement psList = conn.prepareStatement(
                            "SELECT t.id, t.tanggal, u.nama_lengkap, " +
                            "COALESCE(SUM(d.qty), 0) AS total_qty, " +
                            "COALESCE(SUM(d.subtotal), 0) AS revenue, " +
                            "COALESCE(SUM(d.harga_beli * d.qty), 0) AS cost " +
                            "FROM transaksi t " +
                            "LEFT JOIN master_user u ON t.id_user = u.id " +
                            "LEFT JOIN detail_transaksi d ON t.id = d.id_transaksi " +
                            "WHERE t.status = 'selesai' AND DATE(t.tanggal) BETWEEN ? AND ? " +
                            "GROUP BY t.id, t.tanggal, u.nama_lengkap " +
                            "ORDER BY t.tanggal DESC"
                            );
                            psList.setString(1, dateFrom);
                            psList.setString(2, dateTo);
                            ResultSet rsList = psList.executeQuery();
                            while (rsList.next()) {
                            Map<String, Object> row = new HashMap<>();
                                    row.put("id", rsList.getInt("id"));
                                    row.put("tanggal", rsList.getString("tanggal"));
                                    row.put("customer", rsList.getString("nama_lengkap") != null ?
                                    rsList.getString("nama_lengkap") : "Guest");
                                    row.put("qty", rsList.getInt("total_qty"));
                                    row.put("revenue", rsList.getDouble("revenue"));
                                    row.put("cost", rsList.getDouble("cost"));
                                    transactions.add(row);
                                    }
                                    rsList.close(); psList.close();

                                    // Data grafik: omzet & laba per hari (hanya pesanan selesai)
                                    PreparedStatement psChart = conn.prepareStatement(
                                    "SELECT DATE(t.tanggal) AS hari, " +
                                    "COALESCE(SUM(d.subtotal),0) AS rev, " +
                                    "COALESCE(SUM(d.harga_beli * d.qty),0) AS cost " +
                                    "FROM transaksi t LEFT JOIN detail_transaksi d ON t.id = d.id_transaksi " +
                                    "WHERE t.status = 'selesai' AND DATE(t.tanggal) BETWEEN ? AND ? " +
                                    "GROUP BY DATE(t.tanggal) ORDER BY hari ASC");
                                    psChart.setString(1, dateFrom);
                                    psChart.setString(2, dateTo);
                                    ResultSet rsChart = psChart.executeQuery();
                                    while (rsChart.next()) {
                                    double rev = rsChart.getDouble("rev");
                                    double cost = rsChart.getDouble("cost");
                                    chartLabels.add(rsChart.getString("hari"));
                                    chartOmzet.add(rev);
                                    chartLaba.add(rev - cost);
                                    }
                                    rsChart.close(); psChart.close();

                                    conn.close();
                                    } catch (Exception ignored) {}

                                    double totalProfit = totalRevenue - totalCost;
                                    double totalMargin = totalRevenue > 0 ? (totalProfit / totalRevenue) * 100.0 : 0;

                                    String staffName = (String) session.getAttribute("nama_lengkap");
                                    %>
                                    <!DOCTYPE html>
                                    <html lang="en">

                                    <head>
                                        <meta charset="UTF-8">
                                        <title>Laporan Penjualan - VEND.IO Admin</title>
                                        <script src="https://cdn.tailwindcss.com"></script>
                                        <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
                                        <link
                                            href="https://fonts.googleapis.com/css2?family=Inter:wght@400;700;900&display=swap"
                                            rel="stylesheet">
                                        <style>
                                            body {
                                                font-family: 'Inter', sans-serif;
                                                background-color: #e5e7eb;
                                            }

                                            .brutal-shadow {
                                                box-shadow: 8px 8px 0px 0px rgba(0, 0, 0, 1);
                                            }

                                            .brutal-btn-shadow {
                                                box-shadow: 4px 4px 0px 0px rgba(0, 0, 0, 1);
                                            }

                                            .brutal-btn-shadow:active {
                                                box-shadow: 0px 0px 0px 0px rgba(0, 0, 0, 1);
                                                transform: translate(4px, 4px);
                                            }

                                            /* ---- Formal print report (hidden on screen) ---- */
                                            .report {
                                                display: none;
                                            }

                                            @media print {
                                                @page {
                                                    size: A4;
                                                    margin: 18mm 16mm;
                                                }

                                                aside,
                                                .no-print,
                                                .screen-only {
                                                    display: none !important;
                                                }

                                                body {
                                                    display: block !important;
                                                    background: #ffffff !important;
                                                }

                                                main {
                                                    padding: 0 !important;
                                                    overflow: visible !important;
                                                    display: block !important;
                                                }

                                                .report {
                                                    display: block !important;
                                                    font-family: Georgia, 'Times New Roman', serif;
                                                    color: #1a1a1a;
                                                    font-size: 11px;
                                                    line-height: 1.5;
                                                }

                                                .report * {
                                                    box-shadow: none !important;
                                                }

                                                /* Letterhead */
                                                .rpt-head {
                                                    display: flex;
                                                    justify-content: space-between;
                                                    align-items: flex-end;
                                                    border-bottom: 2px solid #1a1a1a;
                                                    padding-bottom: 12px;
                                                    margin-bottom: 4px;
                                                }

                                                .rpt-company {
                                                    font-size: 22px;
                                                    font-weight: 700;
                                                    letter-spacing: .5px;
                                                    margin: 0;
                                                }

                                                .rpt-company-sub {
                                                    font-size: 10px;
                                                    color: #666;
                                                    margin: 2px 0 0;
                                                    font-family: Arial, sans-serif;
                                                    letter-spacing: 1px;
                                                }

                                                .rpt-title-box {
                                                    text-align: right;
                                                }

                                                .rpt-title {
                                                    font-size: 15px;
                                                    font-weight: 700;
                                                    text-transform: uppercase;
                                                    letter-spacing: 2px;
                                                    margin: 0;
                                                }

                                                .rpt-doc {
                                                    font-size: 9px;
                                                    color: #666;
                                                    margin: 2px 0 0;
                                                    font-family: Arial, sans-serif;
                                                }

                                                .rpt-rule-thin {
                                                    border-bottom: 1px solid #1a1a1a;
                                                    margin-bottom: 18px;
                                                }

                                                /* Meta row */
                                                .rpt-meta {
                                                    display: flex;
                                                    justify-content: space-between;
                                                    font-size: 10px;
                                                    margin-bottom: 22px;
                                                    font-family: Arial, sans-serif;
                                                }

                                                .rpt-meta .lbl {
                                                    color: #777;
                                                    text-transform: uppercase;
                                                    letter-spacing: .5px;
                                                    font-size: 8px;
                                                    display: block;
                                                    margin-bottom: 2px;
                                                }

                                                .rpt-meta .val {
                                                    font-weight: 700;
                                                    color: #1a1a1a;
                                                }

                                                /* Section heading */
                                                .rpt-section {
                                                    font-size: 11px;
                                                    font-weight: 700;
                                                    text-transform: uppercase;
                                                    letter-spacing: 1.5px;
                                                    border-bottom: 1px solid #999;
                                                    padding-bottom: 4px;
                                                    margin: 0 0 10px;
                                                }

                                                /* Financial summary */
                                                .rpt-fin {
                                                    width: 100%;
                                                    border-collapse: collapse;
                                                    margin-bottom: 24px;
                                                }

                                                .rpt-fin td {
                                                    padding: 7px 10px;
                                                    font-size: 11px;
                                                    border-bottom: 1px solid #e0e0e0;
                                                }

                                                .rpt-fin td.k {
                                                    color: #444;
                                                }

                                                .rpt-fin td.v {
                                                    text-align: right;
                                                    font-weight: 700;
                                                    font-variant-numeric: tabular-nums;
                                                    white-space: nowrap;
                                                }

                                                .rpt-fin tr.grand td {
                                                    border-top: 2px solid #1a1a1a;
                                                    border-bottom: 2px solid #1a1a1a;
                                                    font-size: 13px;
                                                    font-weight: 700;
                                                    padding-top: 9px;
                                                    padding-bottom: 9px;
                                                }

                                                /* Detail table */
                                                table.rpt-tbl {
                                                    width: 100%;
                                                    border-collapse: collapse;
                                                    margin-bottom: 18px;
                                                }

                                                table.rpt-tbl thead th {
                                                    font-family: Arial, sans-serif;
                                                    font-size: 8.5px;
                                                    text-transform: uppercase;
                                                    letter-spacing: .6px;
                                                    text-align: left;
                                                    padding: 7px 8px;
                                                    border-top: 1.5px solid #1a1a1a;
                                                    border-bottom: 1.5px solid #1a1a1a;
                                                    color: #1a1a1a;
                                                    font-weight: 700;
                                                }

                                                table.rpt-tbl thead th.num {
                                                    text-align: right;
                                                }

                                                table.rpt-tbl tbody td {
                                                    font-size: 10px;
                                                    padding: 6px 8px;
                                                    border-bottom: 1px solid #e6e6e6;
                                                    vertical-align: top;
                                                }

                                                table.rpt-tbl tbody td.num {
                                                    text-align: right;
                                                    font-variant-numeric: tabular-nums;
                                                    white-space: nowrap;
                                                }

                                                table.rpt-tbl tbody tr:nth-child(even) td {
                                                    background: #fafafa;
                                                }

                                                table.rpt-tbl tfoot td {
                                                    font-size: 10.5px;
                                                    font-weight: 700;
                                                    padding: 8px;
                                                    border-top: 1.5px solid #1a1a1a;
                                                    border-bottom: 1.5px solid #1a1a1a;
                                                }

                                                table.rpt-tbl tfoot td.num {
                                                    text-align: right;
                                                    font-variant-numeric: tabular-nums;
                                                    white-space: nowrap;
                                                }

                                                .pos {
                                                    color: #1a1a1a;
                                                }

                                                /* Signature + footer */
                                                .rpt-sign {
                                                    display: flex;
                                                    justify-content: flex-end;
                                                    margin-top: 40px;
                                                }

                                                .rpt-sign-box {
                                                    text-align: center;
                                                    font-family: Arial, sans-serif;
                                                    font-size: 10px;
                                                    width: 200px;
                                                }

                                                .rpt-sign-line {
                                                    border-bottom: 1px solid #1a1a1a;
                                                    height: 48px;
                                                    margin-bottom: 6px;
                                                }

                                                .rpt-foot {
                                                    margin-top: 30px;
                                                    padding-top: 8px;
                                                    border-top: 1px solid #ccc;
                                                    font-family: Arial, sans-serif;
                                                    font-size: 8px;
                                                    color: #999;
                                                    text-align: center;
                                                    letter-spacing: .5px;
                                                }

                                                tr {
                                                    page-break-inside: avoid;
                                                }

                                                thead {
                                                    display: table-header-group;
                                                }
                                            }
                                        </style>
                                    </head>

                                    <body class="flex min-h-screen">

                                        <!-- Sidebar -->
                                        <aside
                                            class="w-64 bg-black text-white flex flex-col justify-between py-6 no-print flex-shrink-0">
                                            <div>
                                                <div class="px-6 flex items-center gap-3 mb-6">
                                                    <div class="bg-[#FACC15] p-2">
                                                        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24"
                                                            viewBox="0 0 24 24" fill="none" stroke="black"
                                                            stroke-width="3" stroke-linecap="round"
                                                            stroke-linejoin="round">
                                                            <circle cx="9" cy="21" r="1"></circle>
                                                            <circle cx="20" cy="21" r="1"></circle>
                                                            <path
                                                                d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6">
                                                            </path>
                                                        </svg>
                                                    </div>
                                                    <h1 class="text-2xl font-[900] italic tracking-tighter">VEND.IO</h1>
                                                </div>
                                                <div class="border-t-[3px] border-white mx-6 mb-8"></div>
                                                <nav class="flex flex-col space-y-2">
                                                    <a href="dashboard.jsp"
                                                        class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">Dashboard</a>
                                                    <a href="pesanan.jsp"
                                                        class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">PESANAN</a>
                                                    <a href="pengiriman.jsp"
                                                        class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">PENGIRIMAN</a>
                                                    <a href="diskon.jsp"
                                                        class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">DISKON & PROMO</a>
                                                    <a href="products.jsp"
                                                        class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">INVENTORY</a>
                                                    <a href="kategori.jsp"
                                                        class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">MASTER
                                                        KATEGORI</a>
                                                    <a href="ukuran.jsp"
                                                        class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">MASTER
                                                        UKURAN</a>
                                                    <a href="users.jsp"
                                                        class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">MASTER
                                                        USER</a>
                                                    <a href="gudang.jsp"
                                                        class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">MASTER
                                                        GUDANG</a>
                                                    <a href="laporan.jsp"
                                                        class="px-6 py-4 font-[900] tracking-wider uppercase bg-[#FACC15] text-black">LAPORAN
                                                        PENJUALAN</a>
                                                </nav>
                                            </div>
                                            <div class="px-6 mt-8">
                                                <div class="border-t-[3px] border-white mb-4"></div>
                                                <p
                                                    class="text-xs font-bold text-gray-400 mb-1 tracking-widest uppercase">
                                                    STAFF</p>
                                                <p class="font-[900] tracking-wider uppercase mb-2 truncate">
                                                    <%= staffName %>
                                                </p>
                                                <a href="logout.jsp"
                                                    class="font-[900] text-red-500 hover:text-red-400 text-sm tracking-wider uppercase">LOG
                                                    OUT</a>
                                            </div>
                                        </aside>

                                        <!-- Main Content -->
                                        <main class="flex-1 p-10 flex flex-col relative overflow-y-auto">

                                            <!-- ============ FORMAL PRINT-ONLY REPORT ============ -->
                                            <div class="report">
                                                <div class="rpt-head">
                                                    <div>
                                                        <p class="rpt-company">VEND.IO</p>
                                                        <p class="rpt-company-sub">RETAIL &amp; SUPERMARKET MANAGEMENT
                                                        </p>
                                                    </div>
                                                    <div class="rpt-title-box">
                                                        <p class="rpt-title">Laporan Penjualan</p>
                                                        <p class="rpt-doc">Sales &amp; Profit Report</p>
                                                    </div>
                                                </div>
                                                <div class="rpt-rule-thin"></div>

                                                <div class="rpt-meta">
                                                    <div>
                                                        <span class="lbl">Periode Laporan</span>
                                                        <span class="val">
                                                            <%= dateFrom %> &nbsp;s/d&nbsp; <%= dateTo %>
                                                        </span>
                                                    </div>
                                                    <div style="text-align:right;">
                                                        <span class="lbl">Dicetak Oleh / Tanggal</span>
                                                        <span class="val">
                                                            <%= staffName %> &bull; <%= today.toString() %>
                                                        </span>
                                                    </div>
                                                </div>

                                                <!-- Financial summary -->
                                                <p class="rpt-section">Ringkasan Keuangan</p>
                                                <table class="rpt-fin">
                                                    <tr>
                                                        <td class="k">Jumlah Transaksi</td>
                                                        <td class="v">
                                                            <%= totalOrders %> transaksi
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <td class="k">Total Item Terjual</td>
                                                        <td class="v">
                                                            <%= totalItemsSold %> pcs
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <td class="k">Pendapatan Penjualan (Omzet)</td>
                                                        <td class="v">Rp <%= String.format("%,.0f", totalRevenue) %>
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <td class="k">Harga Pokok Penjualan (HPP)</td>
                                                        <td class="v">( Rp <%= String.format("%,.0f", totalCost) %> )
                                                        </td>
                                                    </tr>
                                                    <tr class="grand">
                                                        <td class="k">Laba Bersih (Net Profit)</td>
                                                        <td class="v">Rp <%= String.format("%,.0f", totalProfit) %>
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <td class="k">Margin Keuntungan</td>
                                                        <td class="v">
                                                            <%= String.format("%.1f", totalMargin) %> %
                                                        </td>
                                                    </tr>
                                                </table>

                                                <!-- Detail table -->
                                                <p class="rpt-section">Rincian Transaksi</p>
                                                <% if (transactions.isEmpty()) { %>
                                                    <p
                                                        style="font-family:Arial,sans-serif; font-size:11px; color:#777; padding:12px 0;">
                                                        Tidak ada transaksi pada periode ini.
                                                    </p>
                                                    <% } else { %>
                                                        <table class="rpt-tbl">
                                                            <thead>
                                                                <tr>
                                                                    <th style="width:30px;">No</th>
                                                                    <th style="width:55px;">ID</th>
                                                                    <th>Tanggal</th>
                                                                    <th>Pelanggan</th>
                                                                    <th class="num">Qty</th>
                                                                    <th class="num">Omzet</th>
                                                                    <th class="num">HPP</th>
                                                                    <th class="num">Laba</th>
                                                                </tr>
                                                            </thead>
                                                            <tbody>
                                                                <% int pno=1; for (Map<String, Object> trx :
                                                                    transactions) {
                                                                    double rev = (Double) trx.get("revenue");
                                                                    double cost = (Double) trx.get("cost");
                                                                    double prof = rev - cost;
                                                                    %>
                                                                    <tr>
                                                                        <td>
                                                                            <%= pno++ %>
                                                                        </td>
                                                                        <td>#<%= trx.get("id") %>
                                                                        </td>
                                                                        <td>
                                                                            <%= trx.get("tanggal") %>
                                                                        </td>
                                                                        <td>
                                                                            <%= trx.get("customer") %>
                                                                        </td>
                                                                        <td class="num">
                                                                            <%= trx.get("qty") %>
                                                                        </td>
                                                                        <td class="num">Rp <%= String.format("%,.0f",
                                                                                rev) %>
                                                                        </td>
                                                                        <td class="num">Rp <%= String.format("%,.0f",
                                                                                cost) %>
                                                                        </td>
                                                                        <td class="num pos">Rp <%=
                                                                                String.format("%,.0f", prof) %>
                                                                        </td>
                                                                    </tr>
                                                                    <% } %>
                                                            </tbody>
                                                            <tfoot>
                                                                <tr>
                                                                    <td colspan="4">TOTAL</td>
                                                                    <td class="num">
                                                                        <%= totalItemsSold %>
                                                                    </td>
                                                                    <td class="num">Rp <%= String.format("%,.0f",
                                                                            totalRevenue) %>
                                                                    </td>
                                                                    <td class="num">Rp <%= String.format("%,.0f",
                                                                            totalCost) %>
                                                                    </td>
                                                                    <td class="num">Rp <%= String.format("%,.0f",
                                                                            totalProfit) %>
                                                                    </td>
                                                                </tr>
                                                            </tfoot>
                                                        </table>
                                                        <% } %>

                                                            <div class="rpt-sign">
                                                                <div class="rpt-sign-box">
                                                                    <div style="margin-bottom:6px;">Disetujui oleh,
                                                                    </div>
                                                                    <div class="rpt-sign-line"></div>
                                                                    <div>( <%= staffName %> )</div>
                                                                    <div style="color:#777; font-size:9px;">
                                                                        Administrator</div>
                                                                </div>
                                                            </div>

                                                            <div class="rpt-foot">
                                                                Dokumen ini dihasilkan secara otomatis oleh sistem
                                                                VEND.IO &mdash; <%= today.toString() %>
                                                            </div>
                                            </div>
                                            <!-- ============ END FORMAL PRINT REPORT ============ -->

                                            <!-- Screen title row -->
                                            <div class="flex items-center justify-between mb-8 no-print screen-only">
                                                <h2 class="text-4xl font-[900] text-black tracking-tight uppercase m-0">
                                                    LAPORAN PENJUALAN</h2>
                                                <button onclick="window.print()"
                                                    class="flex items-center gap-2 bg-[#FACC15] border-[4px] border-black px-6 py-3 font-[900] text-black tracking-widest uppercase brutal-btn-shadow hover:bg-yellow-400 transition-colors">
                                                    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18"
                                                        viewBox="0 0 24 24" fill="none" stroke="black"
                                                        stroke-width="2.5" stroke-linecap="round"
                                                        stroke-linejoin="round">
                                                        <polyline points="6 9 6 2 18 2 18 9"></polyline>
                                                        <path
                                                            d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2">
                                                        </path>
                                                        <rect x="6" y="14" width="12" height="8"></rect>
                                                    </svg>
                                                    EXPORT PDF
                                                </button>
                                            </div>

                                            <!-- Date range filter -->
                                            <form method="GET" action="laporan.jsp" class="no-print screen-only mb-8">
                                                <div class="bg-black p-3 brutal-shadow">
                                                    <div
                                                        class="bg-white border-[4px] border-black p-5 flex flex-wrap gap-4 items-end">
                                                        <div>
                                                            <label
                                                                class="block font-[900] text-black tracking-wider uppercase mb-1 text-xs">FROM
                                                                DATE</label>
                                                            <input type="date" name="date_from" value="<%= dateFrom %>"
                                                                class="border-[4px] border-black p-2 font-bold text-black focus:outline-none focus:border-[#FACC15] transition-colors">
                                                        </div>
                                                        <div>
                                                            <label
                                                                class="block font-[900] text-black tracking-wider uppercase mb-1 text-xs">TO
                                                                DATE</label>
                                                            <input type="date" name="date_to" value="<%= dateTo %>"
                                                                class="border-[4px] border-black p-2 font-bold text-black focus:outline-none focus:border-[#FACC15] transition-colors">
                                                        </div>
                                                        <button type="submit"
                                                            class="bg-black border-[4px] border-black px-6 py-2 font-[900] text-white tracking-widest uppercase brutal-btn-shadow hover:bg-gray-800 transition-colors">
                                                            APPLY FILTER
                                                        </button>
                                                        <a href="laporan.jsp"
                                                            class="bg-white border-[4px] border-black px-6 py-2 font-[900] text-black tracking-widest uppercase brutal-btn-shadow hover:bg-gray-100 transition-colors">
                                                            RESET
                                                        </a>
                                                    </div>
                                                </div>
                                            </form>

                                            <!-- Summary cards -->
                                            <div
                                                class="grid grid-cols-2 md:grid-cols-4 gap-6 mb-8 no-print screen-only">
                                                <div class="bg-white border-[4px] border-black p-6 brutal-shadow">
                                                    <p
                                                        class="font-[900] text-xs uppercase tracking-widest text-gray-400 m-0 mb-3">
                                                        TOTAL ORDERS</p>
                                                    <p
                                                        class="font-[900] text-5xl text-[#FACC15] drop-shadow-[3px_3px_0px_rgba(0,0,0,1)] m-0">
                                                        <%= totalOrders %>
                                                    </p>
                                                </div>
                                                <div class="bg-white border-[4px] border-black p-6 brutal-shadow">
                                                    <p
                                                        class="font-[900] text-xs uppercase tracking-widest text-gray-400 m-0 mb-3">
                                                        REVENUE (OMZET)</p>
                                                    <p
                                                        class="font-[900] text-2xl text-[#3498DB] drop-shadow-[3px_3px_0px_rgba(0,0,0,1)] m-0 leading-tight">
                                                        Rp<%= String.format("%,.0f", totalRevenue) %>
                                                    </p>
                                                </div>
                                                <div class="bg-white border-[4px] border-black p-6 brutal-shadow">
                                                    <p
                                                        class="font-[900] text-xs uppercase tracking-widest text-gray-400 m-0 mb-3">
                                                        HPP (COST)</p>
                                                    <p
                                                        class="font-[900] text-2xl text-[#EF4444] drop-shadow-[3px_3px_0px_rgba(0,0,0,1)] m-0 leading-tight">
                                                        Rp<%= String.format("%,.0f", totalCost) %>
                                                    </p>
                                                </div>
                                                <div class="bg-white border-[4px] border-black p-6 brutal-shadow">
                                                    <p
                                                        class="font-[900] text-xs uppercase tracking-widest text-gray-400 m-0 mb-3">
                                                        LABA BERSIH &middot; <%= String.format("%.1f", totalMargin) %>%
                                                    </p>
                                                    <p
                                                        class="font-[900] text-2xl text-[#4ADE80] drop-shadow-[3px_3px_0px_rgba(0,0,0,1)] m-0 leading-tight">
                                                        Rp<%= String.format("%,.0f", totalProfit) %>
                                                    </p>
                                                </div>
                                            </div>

                                            <!-- Sales chart -->
                                            <div class="bg-black p-4 brutal-shadow mb-8 no-print screen-only">
                                                <div class="bg-white border-[4px] border-black p-6">
                                                    <h3 class="font-[900] text-xl uppercase tracking-tighter mb-1 m-0">GRAFIK OMZET & LABA</h3>
                                                    <p class="font-bold text-xs text-gray-400 uppercase tracking-widest mb-4 m-0"><%= dateFrom %> — <%= dateTo %> &middot; pesanan selesai</p>
                                                    <% if (chartLabels.isEmpty()) { %>
                                                    <p class="font-bold text-gray-400 text-sm m-0 py-10 text-center">Belum ada penjualan selesai pada periode ini.</p>
                                                    <% } else { %>
                                                    <div style="height:320px;"><canvas id="salesChart"></canvas></div>
                                                    <% } %>
                                                </div>
                                            </div>
                                            <% if (!chartLabels.isEmpty()) { %>
                                            <script>
                                                const sLabels = [<% for (int i=0;i<chartLabels.size();i++){ %>"<%= chartLabels.get(i) %>"<%= i<chartLabels.size()-1?",":"" %><% } %>];
                                                const sOmzet = [<% for (int i=0;i<chartOmzet.size();i++){ %><%= chartOmzet.get(i) %><%= i<chartOmzet.size()-1?",":"" %><% } %>];
                                                const sLaba = [<% for (int i=0;i<chartLaba.size();i++){ %><%= chartLaba.get(i) %><%= i<chartLaba.size()-1?",":"" %><% } %>];
                                                new Chart(document.getElementById('salesChart'), {
                                                    type: 'bar',
                                                    data: { labels: sLabels, datasets: [
                                                        { label: 'Omzet', data: sOmzet, backgroundColor: '#3498DB', borderColor: '#000', borderWidth: 2 },
                                                        { label: 'Laba',  data: sLaba,  backgroundColor: '#4ADE80', borderColor: '#000', borderWidth: 2 }
                                                    ]},
                                                    options: {
                                                        responsive: true, maintainAspectRatio: false,
                                                        plugins: { legend: { labels: { font: { weight: '900' } } } },
                                                        scales: { y: { beginAtZero: true, ticks: { callback: function(v){ return 'Rp' + v.toLocaleString('id-ID'); } } } }
                                                    }
                                                });
                                            </script>
                                            <% } %>

                                            <!-- Transaction table -->
                                            <div
                                                class="bg-black p-4 brutal-shadow flex-1 flex flex-col no-print screen-only">
                                                <div
                                                    class="bg-white border-[4px] border-black flex-1 p-6 flex flex-col">

                                                    <h3 class="font-[900] text-xl uppercase tracking-tighter mb-1 m-0">
                                                        DETAIL TRANSAKSI</h3>
                                                    <p
                                                        class="font-bold text-xs text-gray-400 uppercase tracking-widest mb-6 m-0">
                                                        <%= dateFrom %> — <%= dateTo %>
                                                    </p>

                                                    <% if (transactions.isEmpty()) { %>
                                                        <div class="flex-1 flex items-center justify-center py-16">
                                                            <div class="text-center">
                                                                <p
                                                                    class="font-[900] text-2xl uppercase text-gray-300 m-0">
                                                                    NO TRANSACTIONS FOUND</p>
                                                                <p class="font-bold text-gray-400 text-sm mt-2 m-0">Try
                                                                    adjusting the date range above</p>
                                                            </div>
                                                        </div>
                                                        <% } else { %>
                                                            <div class="overflow-x-auto">
                                                                <table class="w-full text-left">
                                                                    <thead>
                                                                        <tr class="border-b-[4px] border-black">
                                                                            <th
                                                                                class="py-3 pr-4 font-[900] text-black uppercase tracking-wider text-xs">
                                                                                NO</th>
                                                                            <th
                                                                                class="py-3 pr-4 font-[900] text-black uppercase tracking-wider text-xs">
                                                                                ORDER ID</th>
                                                                            <th
                                                                                class="py-3 pr-4 font-[900] text-black uppercase tracking-wider text-xs">
                                                                                DATE & TIME</th>
                                                                            <th
                                                                                class="py-3 pr-4 font-[900] text-black uppercase tracking-wider text-xs">
                                                                                CUSTOMER</th>
                                                                            <th
                                                                                class="py-3 pr-4 font-[900] text-black uppercase tracking-wider text-xs text-center">
                                                                                ITEMS</th>
                                                                            <th
                                                                                class="py-3 pr-4 font-[900] text-black uppercase tracking-wider text-xs text-right">
                                                                                OMZET</th>
                                                                            <th
                                                                                class="py-3 pr-4 font-[900] text-black uppercase tracking-wider text-xs text-right">
                                                                                HPP</th>
                                                                            <th
                                                                                class="py-3 font-[900] text-black uppercase tracking-wider text-xs text-right">
                                                                                LABA</th>
                                                                        </tr>
                                                                    </thead>
                                                                    <tbody>
                                                                        <% int no=1; for (Map<String, Object> trx :
                                                                            transactions) {
                                                                            double rev = (Double) trx.get("revenue");
                                                                            double cost = (Double) trx.get("cost");
                                                                            double prof = rev - cost;
                                                                            %>
                                                                            <tr
                                                                                class="border-b border-gray-200 hover:bg-gray-50 transition-colors">
                                                                                <td
                                                                                    class="py-3 pr-4 font-bold text-gray-400 text-sm">
                                                                                    <%= no++ %>
                                                                                </td>
                                                                                <td class="py-3 pr-4">
                                                                                    <span
                                                                                        class="bg-[#FACC15] border-[2px] border-black px-2 py-0.5 font-[900] text-xs">#
                                                                                        <%= trx.get("id") %>
                                                                                    </span>
                                                                                </td>
                                                                                <td
                                                                                    class="py-3 pr-4 font-bold text-sm text-black whitespace-nowrap">
                                                                                    <%= trx.get("tanggal") %>
                                                                                </td>
                                                                                <td
                                                                                    class="py-3 pr-4 font-[900] text-sm uppercase text-black">
                                                                                    <%= trx.get("customer") %>
                                                                                </td>
                                                                                <td class="py-3 pr-4 text-center">
                                                                                    <span
                                                                                        class="bg-black text-white text-xs font-[900] px-2 py-0.5">
                                                                                        <%= trx.get("qty") %> pcs
                                                                                    </span>
                                                                                </td>
                                                                                <td
                                                                                    class="py-3 pr-4 font-bold text-sm text-right text-black whitespace-nowrap">
                                                                                    Rp<%= String.format("%,.0f", rev) %>
                                                                                </td>
                                                                                <td
                                                                                    class="py-3 pr-4 font-bold text-sm text-right text-red-500 whitespace-nowrap">
                                                                                    Rp<%= String.format("%,.0f", cost)
                                                                                        %>
                                                                                </td>
                                                                                <td
                                                                                    class="py-3 font-[900] text-sm text-right text-green-600 whitespace-nowrap">
                                                                                    Rp<%= String.format("%,.0f", prof)
                                                                                        %>
                                                                                </td>
                                                                            </tr>
                                                                            <% } %>
                                                                    </tbody>
                                                                    <tfoot>
                                                                        <tr
                                                                            class="border-t-[4px] border-black bg-[#FACC15]">
                                                                            <td colspan="4"
                                                                                class="py-4 pr-4 font-[900] uppercase tracking-wider text-sm">
                                                                                GRAND TOTAL (<%= transactions.size() %>
                                                                                    orders)
                                                                            </td>
                                                                            <td
                                                                                class="py-4 pr-4 text-center font-[900] text-sm">
                                                                                <%= totalItemsSold %> pcs
                                                                            </td>
                                                                            <td
                                                                                class="py-4 pr-4 font-[900] text-right text-black whitespace-nowrap text-sm">
                                                                                Rp<%= String.format("%,.0f",
                                                                                    totalRevenue) %>
                                                                            </td>
                                                                            <td
                                                                                class="py-4 pr-4 font-[900] text-right text-black whitespace-nowrap text-sm">
                                                                                Rp<%= String.format("%,.0f", totalCost)
                                                                                    %>
                                                                            </td>
                                                                            <td
                                                                                class="py-4 font-[900] text-right text-black whitespace-nowrap text-base">
                                                                                Rp<%= String.format("%,.0f",
                                                                                    totalProfit) %>
                                                                            </td>
                                                                        </tr>
                                                                    </tfoot>
                                                                </table>
                                                            </div>
                                                            <% } %>
                                                </div>
                                            </div>

                                            <p
                                                class="mt-6 font-bold text-gray-400 text-sm no-print screen-only text-right">
                                                Developed by Dandy & Verly</p>
                                        </main>

                                    </body>

                                    </html>