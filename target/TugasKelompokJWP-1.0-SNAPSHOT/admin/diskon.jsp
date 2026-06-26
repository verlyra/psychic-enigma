<%@page import="jdbc.koneksi"%>
<%@page import="jdbc.DbInit"%>
<%@page import="java.sql.*"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    if(session.getAttribute("user_id") == null || !"admin".equals(session.getAttribute("role"))) {
        response.sendRedirect("login.jsp");
        return;
    }

    String action = request.getParameter("action");

    if(("add".equals(action) || "edit".equals(action)) && "POST".equalsIgnoreCase(request.getMethod())) {
        try {
            koneksi k = new koneksi(); Connection conn = k.bukaKoneksi(); DbInit.ensureSchema(conn);
            String nama   = request.getParameter("nama");
            String tipe   = "voucher".equals(request.getParameter("tipe")) ? "voucher" : "auto";
            String kode   = request.getParameter("kode");
            if (kode != null) kode = kode.trim().toUpperCase();
            if (kode != null && kode.isEmpty()) kode = null;
            String jenis  = "persen".equals(request.getParameter("jenis_potongan")) ? "persen" : "nominal";
            double nilai  = Double.parseDouble(request.getParameter("nilai"));
            double minB   = request.getParameter("min_belanja").isEmpty() ? 0 : Double.parseDouble(request.getParameter("min_belanja"));
            double maks   = request.getParameter("maks_potongan").isEmpty() ? 0 : Double.parseDouble(request.getParameter("maks_potongan"));
            int aktif     = request.getParameter("aktif") != null ? 1 : 0;
            String tMulai = request.getParameter("tanggal_mulai");
            String tSelesai = request.getParameter("tanggal_selesai");
            if (tMulai != null && tMulai.isEmpty()) tMulai = null;
            if (tSelesai != null && tSelesai.isEmpty()) tSelesai = null;

            PreparedStatement ps;
            if ("add".equals(action)) {
                ps = conn.prepareStatement(
                    "INSERT INTO master_diskon (nama, tipe, kode, jenis_potongan, nilai, min_belanja, maks_potongan, aktif, tanggal_mulai, tanggal_selesai) VALUES (?,?,?,?,?,?,?,?,?,?)");
            } else {
                ps = conn.prepareStatement(
                    "UPDATE master_diskon SET nama=?, tipe=?, kode=?, jenis_potongan=?, nilai=?, min_belanja=?, maks_potongan=?, aktif=?, tanggal_mulai=?, tanggal_selesai=? WHERE id=?");
            }
            ps.setString(1, nama);
            ps.setString(2, tipe);
            if (kode == null) ps.setNull(3, Types.VARCHAR); else ps.setString(3, kode);
            ps.setString(4, jenis);
            ps.setDouble(5, nilai);
            ps.setDouble(6, minB);
            ps.setDouble(7, maks);
            ps.setInt(8, aktif);
            if (tMulai == null) ps.setNull(9, Types.DATE); else ps.setString(9, tMulai);
            if (tSelesai == null) ps.setNull(10, Types.DATE); else ps.setString(10, tSelesai);
            if ("edit".equals(action)) ps.setInt(11, Integer.parseInt(request.getParameter("id")));
            ps.executeUpdate(); ps.close(); conn.close();
            response.sendRedirect("diskon.jsp"); return;
        } catch(Exception e) { out.println("Error: " + e.getMessage()); }
    } else if("delete".equals(action)) {
        try {
            koneksi k = new koneksi(); Connection conn = k.bukaKoneksi();
            PreparedStatement ps = conn.prepareStatement("DELETE FROM master_diskon WHERE id = ?");
            ps.setInt(1, Integer.parseInt(request.getParameter("id")));
            ps.executeUpdate(); ps.close(); conn.close();
            response.sendRedirect("diskon.jsp"); return;
        } catch(Exception e) { out.println("Error: " + e.getMessage()); }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Diskon & Promo - VEND.IO Admin</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;700;900&display=swap" rel="stylesheet">
    <style>
        body { font-family: 'Inter', sans-serif; background-color: #e5e7eb; }
        .brutal-shadow { box-shadow: 8px 8px 0px 0px rgba(0,0,0,1); }
        .brutal-btn-shadow { box-shadow: 4px 4px 0px 0px rgba(0,0,0,1); }
        .brutal-btn-shadow:active { box-shadow: 0px 0px 0px 0px rgba(0,0,0,1); transform: translate(4px, 4px); }
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
                <a href="dashboard.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">Dashboard</a>
                <a href="pesanan.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">PESANAN</a>
                <a href="pengiriman.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">PENGIRIMAN</a>
                <a href="diskon.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase bg-[#FACC15] text-black">DISKON & PROMO</a>
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

    <!-- Main -->
    <main class="flex-1 p-10 flex flex-col relative overflow-y-auto">
        <h2 class="text-4xl font-[900] text-black tracking-tight uppercase mb-8">DISKON & PROMO</h2>

        <div class="bg-black p-4 w-full brutal-shadow flex-1 flex flex-col">
            <div class="bg-white border-[4px] border-black flex-1 p-6 relative flex flex-col">
                <h3 class="font-[900] text-2xl uppercase tracking-tighter mb-6 text-white bg-black inline-block relative -top-12 -left-2 px-4 pb-0 pt-2">DAFTAR DISKON</h3>

                <div class="overflow-x-auto -mt-6">
                <table class="w-full text-left mb-auto">
                    <thead>
                        <tr class="border-b-[4px] border-black">
                            <th class="py-3 font-[900] text-black uppercase tracking-wider text-xs">ID</th>
                            <th class="py-3 font-[900] text-black uppercase tracking-wider text-xs">NAMA</th>
                            <th class="py-3 font-[900] text-black uppercase tracking-wider text-xs">TIPE</th>
                            <th class="py-3 font-[900] text-black uppercase tracking-wider text-xs">KODE</th>
                            <th class="py-3 font-[900] text-black uppercase tracking-wider text-xs">POTONGAN</th>
                            <th class="py-3 font-[900] text-black uppercase tracking-wider text-xs text-right">MIN. BELANJA</th>
                            <th class="py-3 font-[900] text-black uppercase tracking-wider text-xs text-center">AKTIF</th>
                            <th class="py-3 font-[900] text-black uppercase tracking-wider text-xs text-right">ACTION</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                            try {
                                koneksi k = new koneksi(); Connection conn = k.bukaKoneksi(); DbInit.ensureSchema(conn);
                                Statement stmt = conn.createStatement();
                                ResultSet rs = stmt.executeQuery("SELECT * FROM master_diskon ORDER BY id DESC");
                                while(rs.next()) {
                                    String tipe = rs.getString("tipe");
                                    String kode = rs.getString("kode") != null ? rs.getString("kode") : "-";
                                    String jenis = rs.getString("jenis_potongan");
                                    double nilai = rs.getDouble("nilai");
                                    int aktif = rs.getInt("aktif");
                                    String tMulai = rs.getString("tanggal_mulai") != null ? rs.getString("tanggal_mulai") : "";
                                    String tSelesai = rs.getString("tanggal_selesai") != null ? rs.getString("tanggal_selesai") : "";
                                    String potonganStr = "persen".equals(jenis) ? (String.format("%,.0f", nilai) + "%") : ("Rp" + String.format("%,.0f", nilai));
                        %>
                        <tr class="font-bold border-b border-gray-200">
                            <td class="py-3 text-xs"><%= rs.getInt("id") %></td>
                            <td class="py-3 uppercase text-xs"><%= rs.getString("nama") %></td>
                            <td class="py-3 text-xs">
                                <% if ("voucher".equals(tipe)) { %><span class="bg-[#A855F7] text-white border-[2px] border-black px-2 py-0.5 font-[900] uppercase">VOUCHER</span>
                                <% } else { %><span class="bg-[#3498DB] text-white border-[2px] border-black px-2 py-0.5 font-[900] uppercase">AUTO</span><% } %>
                            </td>
                            <td class="py-3 uppercase text-xs font-[900]"><%= kode %></td>
                            <td class="py-3 text-xs font-[900]"><%= potonganStr %><% if (rs.getDouble("maks_potongan") > 0) { %> <span class="text-gray-400">(max Rp<%= String.format("%,.0f", rs.getDouble("maks_potongan")) %>)</span><% } %></td>
                            <td class="py-3 text-right text-xs">Rp<%= String.format("%,.0f", rs.getDouble("min_belanja")) %></td>
                            <td class="py-3 text-center">
                                <% if (aktif == 1) { %><span class="bg-[#4ADE80] border-[2px] border-black px-2 py-0.5 font-[900] text-xs uppercase">ON</span>
                                <% } else { %><span class="bg-gray-300 border-[2px] border-black px-2 py-0.5 font-[900] text-xs uppercase">OFF</span><% } %>
                            </td>
                            <td class="py-3 text-right whitespace-nowrap">
                                <a href="javascript:void(0)" onclick='openEdit(<%= rs.getInt("id") %>, <%= toJs(rs.getString("nama")) %>, "<%= tipe %>", <%= toJs(rs.getString("kode")) %>, "<%= jenis %>", <%= nilai %>, <%= rs.getDouble("min_belanja") %>, <%= rs.getDouble("maks_potongan") %>, <%= aktif %>, "<%= tMulai %>", "<%= tSelesai %>")' class="text-[#3498DB] font-[900] uppercase text-sm">EDIT</a>
                                <span class="text-black font-black mx-1">|</span>
                                <a href="diskon.jsp?action=delete&id=<%= rs.getInt("id") %>" class="text-red-500 hover:text-red-700 font-[900] uppercase text-sm" onclick="return confirm('Hapus diskon ini?');">DELETE</a>
                            </td>
                        </tr>
                        <%      }
                                rs.close(); stmt.close(); conn.close();
                            } catch(Exception e) { out.println("<tr><td colspan='8'>Error: " + e.getMessage() + "</td></tr>"); }
                        %>
                    </tbody>
                </table>
                </div>

                <div class="flex justify-end mt-8">
                    <button onclick="openAdd()" class="bg-[#3498DB] border-[4px] border-black px-6 py-3 font-[900] text-white tracking-wider uppercase brutal-btn-shadow hover:bg-blue-600 transition-colors">+ ADD DISKON</button>
                </div>
            </div>
        </div>

        <p class="mt-6 font-bold text-gray-400 text-sm text-right">Developed by Dandy & Verly</p>
    </main>

    <!-- Modal Form (dipakai add & edit) -->
    <div id="formModal" class="fixed inset-0 bg-black bg-opacity-50 z-50 hidden flex items-center justify-center p-4">
        <div class="bg-black p-3 w-full max-w-2xl brutal-shadow">
            <div class="bg-white border-[4px] border-black p-8 relative max-h-[90vh] overflow-y-auto">
                <h3 id="formTitle" class="font-[900] text-2xl uppercase tracking-tighter mb-6 text-white bg-black inline-block absolute -top-8 -left-3 px-4 py-2">ADD DISKON</h3>
                <form id="diskonForm" action="diskon.jsp?action=add" method="POST" class="grid grid-cols-1 gap-5 mt-6">
                    <input type="hidden" name="id" id="f_id">
                    <div>
                        <label class="block font-[900] text-black tracking-wider uppercase mb-1 text-sm">NAMA DISKON</label>
                        <input type="text" name="nama" id="f_nama" required class="w-full border-[4px] border-black p-3 font-bold text-black focus:outline-none">
                    </div>
                    <div class="grid grid-cols-2 gap-5">
                        <div>
                            <label class="block font-[900] text-black tracking-wider uppercase mb-1 text-sm">TIPE</label>
                            <select name="tipe" id="f_tipe" onchange="toggleKode()" class="w-full border-[4px] border-black p-3 font-bold text-black focus:outline-none">
                                <option value="auto">AUTO (otomatis)</option>
                                <option value="voucher">VOUCHER (pakai kode)</option>
                            </select>
                        </div>
                        <div id="kodeWrap">
                            <label class="block font-[900] text-black tracking-wider uppercase mb-1 text-sm">KODE VOUCHER</label>
                            <input type="text" name="kode" id="f_kode" placeholder="HEMAT5K" class="w-full border-[4px] border-black p-3 font-bold text-black focus:outline-none uppercase">
                        </div>
                    </div>
                    <div class="grid grid-cols-2 gap-5">
                        <div>
                            <label class="block font-[900] text-black tracking-wider uppercase mb-1 text-sm">JENIS POTONGAN</label>
                            <select name="jenis_potongan" id="f_jenis" class="w-full border-[4px] border-black p-3 font-bold text-black focus:outline-none">
                                <option value="nominal">NOMINAL (Rp)</option>
                                <option value="persen">PERSEN (%)</option>
                            </select>
                        </div>
                        <div>
                            <label class="block font-[900] text-black tracking-wider uppercase mb-1 text-sm">NILAI</label>
                            <input type="number" name="nilai" id="f_nilai" required min="0" step="any" class="w-full border-[4px] border-black p-3 font-bold text-black focus:outline-none">
                        </div>
                    </div>
                    <div class="grid grid-cols-2 gap-5">
                        <div>
                            <label class="block font-[900] text-black tracking-wider uppercase mb-1 text-sm">MIN. BELANJA (Rp)</label>
                            <input type="number" name="min_belanja" id="f_min" min="0" step="any" value="0" class="w-full border-[4px] border-black p-3 font-bold text-black focus:outline-none">
                        </div>
                        <div>
                            <label class="block font-[900] text-black tracking-wider uppercase mb-1 text-sm">MAKS. POTONGAN (Rp, utk %)</label>
                            <input type="number" name="maks_potongan" id="f_maks" min="0" step="any" value="0" class="w-full border-[4px] border-black p-3 font-bold text-black focus:outline-none">
                        </div>
                    </div>
                    <div class="grid grid-cols-2 gap-5">
                        <div>
                            <label class="block font-[900] text-black tracking-wider uppercase mb-1 text-sm">MULAI (opsional)</label>
                            <input type="date" name="tanggal_mulai" id="f_mulai" class="w-full border-[4px] border-black p-3 font-bold text-black focus:outline-none">
                        </div>
                        <div>
                            <label class="block font-[900] text-black tracking-wider uppercase mb-1 text-sm">SELESAI (opsional)</label>
                            <input type="date" name="tanggal_selesai" id="f_selesai" class="w-full border-[4px] border-black p-3 font-bold text-black focus:outline-none">
                        </div>
                    </div>
                    <label class="flex items-center gap-2 font-[900] uppercase text-sm"><input type="checkbox" name="aktif" id="f_aktif" checked class="w-5 h-5 accent-black"> AKTIF</label>
                    <div class="flex items-center gap-4 mt-2">
                        <button type="submit" class="bg-[#3498DB] border-[4px] border-black px-8 py-3 font-[900] text-white tracking-wider uppercase brutal-btn-shadow hover:bg-blue-600 transition-colors flex-1">SAVE</button>
                        <button type="button" onclick="document.getElementById('formModal').classList.add('hidden')" class="bg-white border-[4px] border-black px-8 py-3 font-[900] text-black tracking-wider uppercase brutal-btn-shadow hover:bg-gray-100 transition-colors">CANCEL</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <script>
        function toggleKode() {
            var tipe = document.getElementById('f_tipe').value;
            document.getElementById('kodeWrap').style.display = (tipe === 'voucher') ? 'block' : 'none';
        }
        function openAdd() {
            document.getElementById('formTitle').textContent = 'ADD DISKON';
            document.getElementById('diskonForm').action = 'diskon.jsp?action=add';
            document.getElementById('f_id').value = '';
            document.getElementById('f_nama').value = '';
            document.getElementById('f_tipe').value = 'auto';
            document.getElementById('f_kode').value = '';
            document.getElementById('f_jenis').value = 'nominal';
            document.getElementById('f_nilai').value = '';
            document.getElementById('f_min').value = '0';
            document.getElementById('f_maks').value = '0';
            document.getElementById('f_mulai').value = '';
            document.getElementById('f_selesai').value = '';
            document.getElementById('f_aktif').checked = true;
            toggleKode();
            document.getElementById('formModal').classList.remove('hidden');
        }
        function openEdit(id, nama, tipe, kode, jenis, nilai, minB, maks, aktif, tMulai, tSelesai) {
            document.getElementById('formTitle').textContent = 'EDIT DISKON';
            document.getElementById('diskonForm').action = 'diskon.jsp?action=edit';
            document.getElementById('f_id').value = id;
            document.getElementById('f_nama').value = nama;
            document.getElementById('f_tipe').value = tipe;
            document.getElementById('f_kode').value = kode || '';
            document.getElementById('f_jenis').value = jenis;
            document.getElementById('f_nilai').value = nilai;
            document.getElementById('f_min').value = minB;
            document.getElementById('f_maks').value = maks;
            document.getElementById('f_mulai').value = tMulai || '';
            document.getElementById('f_selesai').value = tSelesai || '';
            document.getElementById('f_aktif').checked = (aktif == 1);
            toggleKode();
            document.getElementById('formModal').classList.remove('hidden');
        }
    </script>
</body>
</html>
<%!
    // Encode string Java -> literal JS yang aman (untuk atribut onclick)
    String toJs(String s) {
        if (s == null) return "\"\"";
        String e = s.replace("\\", "\\\\").replace("\"", "\\\"").replace("'", "\\'")
                    .replace("\r", " ").replace("\n", " ");
        return "\"" + e + "\"";
    }
%>
