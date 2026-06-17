<%@page import="jdbc.koneksi"%>
<%@page import="java.sql.*"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    if(session.getAttribute("user_id") == null || !"admin".equals(session.getAttribute("role"))) {
        response.sendRedirect("login.jsp");
        return;
    }

    String action = request.getParameter("action");
    if("add".equals(action) && "POST".equalsIgnoreCase(request.getMethod())) {
        try {
            koneksi k = new koneksi();
            Connection conn = k.bukaKoneksi();
            String sql = "INSERT INTO master_product (nama_produk, harga_jual, harga_beli, merk, id_ukuran, stok, deskripsi, image_url, id_kategori, id_gudang) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            PreparedStatement pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, request.getParameter("nama_produk"));
            pstmt.setDouble(2, Double.parseDouble(request.getParameter("harga_jual")));
            pstmt.setDouble(3, request.getParameter("harga_beli") != null && !request.getParameter("harga_beli").isEmpty() ? Double.parseDouble(request.getParameter("harga_beli")) : 0);
            pstmt.setString(4, request.getParameter("merk"));
            
            String idUkuranStr = request.getParameter("id_ukuran");
            if(idUkuranStr != null && !idUkuranStr.isEmpty()) pstmt.setInt(5, Integer.parseInt(idUkuranStr));
            else pstmt.setNull(5, java.sql.Types.INTEGER);
            
            pstmt.setInt(6, Integer.parseInt(request.getParameter("stok")));
            pstmt.setString(7, request.getParameter("deskripsi"));
            pstmt.setString(8, request.getParameter("image_url"));
            pstmt.setInt(9, Integer.parseInt(request.getParameter("id_kategori")));
            
            String idGudangStr = request.getParameter("id_gudang");
            if(idGudangStr != null && !idGudangStr.isEmpty()) pstmt.setInt(10, Integer.parseInt(idGudangStr));
            else pstmt.setNull(10, java.sql.Types.INTEGER);
            
            pstmt.executeUpdate();
            pstmt.close();
            conn.close();
            response.sendRedirect("products.jsp");
            return;
        } catch(Exception e) { out.println("Error: " + e.getMessage()); }
    } else if("edit".equals(action) && "POST".equalsIgnoreCase(request.getMethod())) {
        try {
            koneksi k = new koneksi();
            Connection conn = k.bukaKoneksi();
            String sql = "UPDATE master_product SET nama_produk=?, harga_jual=?, harga_beli=?, merk=?, id_ukuran=?, stok=?, deskripsi=?, image_url=?, id_kategori=?, id_gudang=? WHERE id=?";
            PreparedStatement pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, request.getParameter("nama_produk"));
            pstmt.setDouble(2, Double.parseDouble(request.getParameter("harga_jual")));
            pstmt.setDouble(3, request.getParameter("harga_beli") != null && !request.getParameter("harga_beli").isEmpty() ? Double.parseDouble(request.getParameter("harga_beli")) : 0);
            pstmt.setString(4, request.getParameter("merk"));
            
            String idUkuranStr = request.getParameter("id_ukuran");
            if(idUkuranStr != null && !idUkuranStr.isEmpty()) pstmt.setInt(5, Integer.parseInt(idUkuranStr));
            else pstmt.setNull(5, java.sql.Types.INTEGER);
            
            pstmt.setInt(6, Integer.parseInt(request.getParameter("stok")));
            pstmt.setString(7, request.getParameter("deskripsi"));
            pstmt.setString(8, request.getParameter("image_url"));
            pstmt.setInt(9, Integer.parseInt(request.getParameter("id_kategori")));
            
            String idGudangStr = request.getParameter("id_gudang");
            if(idGudangStr != null && !idGudangStr.isEmpty()) pstmt.setInt(10, Integer.parseInt(idGudangStr));
            else pstmt.setNull(10, java.sql.Types.INTEGER);
            
            pstmt.setInt(11, Integer.parseInt(request.getParameter("id")));
            pstmt.executeUpdate();
            pstmt.close();
            conn.close();
            response.sendRedirect("products.jsp");
            return;
        } catch(Exception e) { out.println("Error: " + e.getMessage()); }
    } else if("delete".equals(action)) {
        try {
            koneksi k = new koneksi();
            Connection conn = k.bukaKoneksi();
            PreparedStatement pstmt = conn.prepareStatement("DELETE FROM master_product WHERE id = ?");
            pstmt.setInt(1, Integer.parseInt(request.getParameter("id")));
            pstmt.executeUpdate();
            pstmt.close();
            conn.close();
            response.sendRedirect("products.jsp");
            return;
        } catch(Exception e) { out.println("Error: " + e.getMessage()); }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Inventory - VEND.IO Admin</title>
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
    <aside class="w-64 bg-black text-white flex flex-col justify-between py-6">
        <div>
            <!-- Logo -->
            <div class="px-6 flex items-center gap-3 mb-6">
                <div class="bg-[#FACC15] p-2">
                    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="black" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="9" cy="21" r="1"></circle><circle cx="20" cy="21" r="1"></circle><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"></path>
                    </svg>
                </div>
                <h1 class="text-2xl font-[900] italic tracking-tighter">VEND.IO</h1>
            </div>
            <div class="border-t-[3px] border-white mx-6 mb-8"></div>
            
            <!-- Menu -->
            <nav class="flex flex-col space-y-2">
                <a href="dashboard.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">Dashboard</a>
                <a href="products.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase bg-[#FACC15] text-black">INVENTORY</a>
                <a href="kategori.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">MASTER KATEGORI</a>
                <a href="ukuran.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">MASTER UKURAN</a>
                <a href="users.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">MASTER USER</a>
                <a href="gudang.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">MASTER GUDANG</a>
            </nav>
        </div>
        
        <!-- Staff Info -->
        <div class="px-6 mt-8">
            <div class="border-t-[3px] border-white mb-4"></div>
            <p class="text-xs font-bold text-gray-400 mb-1 tracking-widest uppercase">STAFF</p>
            <p class="font-[900] tracking-wider uppercase mb-2 truncate"><%= session.getAttribute("nama_lengkap") %></p>
            <a href="logout.jsp" class="font-[900] text-red-500 hover:text-red-400 text-sm tracking-wider uppercase">LOG OUT</a>
        </div>
    </aside>

    <!-- Main Content -->
    <main class="flex-1 p-10 flex flex-col relative">
        <h2 class="text-4xl font-[900] text-black tracking-tight uppercase mb-8">INVENTORY</h2>

        <div class="bg-black p-4 w-full brutal-shadow flex-1 flex flex-col">
            <div class="bg-white border-[4px] border-black flex-1 p-6 relative flex flex-col">
                <h3 class="font-[900] text-2xl uppercase tracking-tighter mb-6 text-black bg-white inline-block relative -top-12 -left-2 px-2 pb-0 pt-2">INVENTORY</h3>
                
                <div class="-mt-8 mb-4">
                    <input type="text" id="searchInput" onkeyup="searchProduct()" placeholder="SEARCH PRODUCT BY NAME OR BRAND..." class="w-full border-[4px] border-black p-3 font-[900] text-black tracking-wider uppercase focus:outline-none">
                </div>

                <div class="overflow-x-auto mb-auto">
                    <table class="w-full text-left" id="productTable">
                        <thead>
                            <tr class="border-b-[4px] border-black">
                                <th class="py-3 font-[900] text-black uppercase tracking-wider text-xs">ID</th>
                                <th class="py-3 font-[900] text-black uppercase tracking-wider text-xs">NAME</th>
                                <th class="py-3 font-[900] text-black uppercase tracking-wider text-xs">BRAND</th>
                                <th class="py-3 font-[900] text-black uppercase tracking-wider text-xs">SIZE</th>
                                <th class="py-3 font-[900] text-black uppercase tracking-wider text-xs">CATEGORY</th>
                                <th class="py-3 font-[900] text-black uppercase tracking-wider text-xs">BUY PRICE</th>
                                <th class="py-3 font-[900] text-black uppercase tracking-wider text-xs">SELL PRICE</th>
                                <th class="py-3 font-[900] text-black uppercase tracking-wider text-xs">STOCK</th>
                                <th class="py-3 font-[900] text-black uppercase tracking-wider text-xs text-right whitespace-nowrap">ACTION</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                try {
                                    koneksi k = new koneksi();
                                    Connection conn = k.bukaKoneksi();
                                    Statement stmt = conn.createStatement();
                                    ResultSet rs = stmt.executeQuery("SELECT p.*, g.nama_gudang, k.nama_kategori, u.nama_ukuran FROM master_product p LEFT JOIN master_gudang g ON p.id_gudang = g.id LEFT JOIN master_kategori k ON p.id_kategori = k.id LEFT JOIN master_ukuran u ON p.id_ukuran = u.id ORDER BY p.id DESC");
                                    while(rs.next()) {
                                        String kat = rs.getString("nama_kategori") != null ? rs.getString("nama_kategori") : "-";
                                        String brand = rs.getString("merk") != null ? rs.getString("merk") : "-";
                                        String ukuran = rs.getString("nama_ukuran") != null ? rs.getString("nama_ukuran") : "-";
                            %>
                            <tr class="font-bold border-b border-gray-200">
                                <td class="py-4 text-sm"><%= rs.getInt("id") %></td>
                                <td class="py-4 uppercase text-sm"><%= rs.getString("nama_produk") %></td>
                                <td class="py-4 uppercase text-sm"><%= brand %></td>
                                <td class="py-4 uppercase text-sm"><%= ukuran %></td>
                                <td class="py-4 text-sm"><span class="bg-[#4ADE80] text-black px-2 py-1 font-[900] text-xs uppercase"><%= kat %></span></td>
                                <td class="py-4 text-sm">Rp <%= String.format("%,.0f", rs.getDouble("harga_beli")) %></td>
                                <td class="py-4 text-sm text-blue-600">Rp <%= String.format("%,.0f", rs.getDouble("harga_jual")) %></td>
                                <td class="py-4 text-sm"><%= rs.getInt("stok") %></td>
                                <td class="py-4 text-right whitespace-nowrap">
                                    <a href="javascript:void(0)" onclick="openEditProduct(<%= rs.getInt("id") %>, '<%= rs.getString("nama_produk").replace("'", "\\'") %>', '<%= brand.replace("'", "\\'") %>', <%= rs.getDouble("harga_beli") %>, <%= rs.getDouble("harga_jual") %>, <%= rs.getInt("stok") %>, '<%= rs.getString("deskripsi") != null ? rs.getString("deskripsi").replace("'", "\\'").replace("\n", " ") : "" %>', '<%= rs.getString("image_url") != null ? rs.getString("image_url").replace("'", "\\'") : "" %>', '<%= rs.getString("id_kategori") != null ? rs.getString("id_kategori") : "" %>', '<%= rs.getString("id_gudang") != null ? rs.getString("id_gudang") : "" %>', '<%= rs.getString("id_ukuran") != null ? rs.getString("id_ukuran") : "" %>')" class="text-[#3498DB] font-[900] uppercase text-sm">EDIT</a>
                                    <span class="text-black font-black mx-1">|</span>
                                    <a href="products.jsp?action=delete&id=<%= rs.getInt("id") %>" class="text-red-500 hover:text-red-700 font-[900] uppercase text-sm" onclick="return confirm('Hapus produk ini?');">DELETE</a>
                                </td>
                            </tr>
                            <%      }
                                    rs.close(); stmt.close(); conn.close();
                                } catch(Exception e) { out.println("<tr><td colspan='9'>Error: " + e.getMessage() + "</td></tr>"); }
                            %>
                        </tbody>
                    </table>
                </div>

                <div class="flex justify-end mt-8">
                    <button onclick="document.getElementById('addModal').classList.remove('hidden')" class="bg-[#4ADE80] border-[4px] border-black px-6 py-3 font-[900] text-black tracking-wider uppercase brutal-btn-shadow hover:bg-green-500 transition-colors">
                        + ADD ITEM
                    </button>
                </div>
            </div>
        </div>

        <p class="absolute bottom-4 right-10 font-bold text-gray-400 text-sm">Developed by Dandy & Verly</p>
    </main>

    <!-- Modal Add Item -->
    <div id="addModal" class="fixed inset-0 bg-black bg-opacity-50 z-50 hidden flex items-center justify-center p-4">
        <!-- brutalist modal -->
        <div class="bg-black p-3 w-full max-w-3xl brutal-shadow">
            <div class="bg-white border-[4px] border-black p-8 relative max-h-[90vh] overflow-y-auto">
                <h3 class="font-[900] text-2xl uppercase tracking-tighter mb-6 text-white bg-black inline-block absolute -top-8 -left-3 px-4 py-2">ADD NEW ITEMS</h3>
                
                <form action="products.jsp?action=add" method="POST" class="grid grid-cols-2 gap-4 mt-6">
                    <div class="col-span-2 sm:col-span-1">
                        <label class="block font-[900] text-black tracking-wider uppercase mb-1 text-sm">PRODUCT NAME</label>
                        <input type="text" name="nama_produk" required class="w-full border-[4px] border-black p-2 font-bold text-black focus:outline-none">
                    </div>
                    <div class="col-span-2 sm:col-span-1">
                        <label class="block font-[900] text-black tracking-wider uppercase mb-1 text-sm">BRAND / MERK</label>
                        <input type="text" name="merk" class="w-full border-[4px] border-black p-2 font-bold text-black focus:outline-none">
                    </div>
                    
                    <div class="col-span-2 sm:col-span-1">
                        <label class="block font-[900] text-black tracking-wider uppercase mb-1 text-sm">BUYING PRICE (IDR)</label>
                        <input type="number" name="harga_beli" class="w-full border-[4px] border-black p-2 font-bold text-black focus:outline-none">
                    </div>
                    <div class="col-span-2 sm:col-span-1">
                        <label class="block font-[900] text-black tracking-wider uppercase mb-1 text-sm">SELLING PRICE (IDR)</label>
                        <input type="number" name="harga_jual" required class="w-full border-[4px] border-black p-2 font-bold text-black focus:outline-none">
                    </div>

                    <div class="col-span-1">
                        <label class="block font-[900] text-black tracking-wider uppercase mb-1 text-sm">AVAILABLE STOCK</label>
                        <input type="number" name="stok" required class="w-full border-[4px] border-black p-2 font-bold text-black focus:outline-none">
                    </div>
                    <div class="col-span-1">
                        <label class="block font-[900] text-black tracking-wider uppercase mb-1 text-sm">SIZE / UNIT</label>
                        <select name="id_ukuran" class="w-full border-[4px] border-black p-2 font-bold text-black focus:outline-none">
                            <option value="">- SELECT SIZE -</option>
                            <%
                                try {
                                    koneksi kUku = new koneksi();
                                    Connection connUku = kUku.bukaKoneksi();
                                    ResultSet rsUku = connUku.createStatement().executeQuery("SELECT id, nama_ukuran FROM master_ukuran");
                                    while(rsUku.next()) {
                                        out.print("<option value='"+rsUku.getInt("id")+"'>"+rsUku.getString("nama_ukuran")+"</option>");
                                    }
                                    rsUku.close(); connUku.close();
                                } catch(Exception ignored) {}
                            %>
                        </select>
                    </div>

                    <div class="col-span-1">
                        <label class="block font-[900] text-black tracking-wider uppercase mb-1 text-sm">CATEGORY</label>
                        <select name="id_kategori" required class="w-full border-[4px] border-black p-2 font-bold text-black focus:outline-none">
                            <option value="">- SELECT CATEGORY -</option>
                            <%
                                try {
                                    koneksi kKat = new koneksi();
                                    Connection connKat = kKat.bukaKoneksi();
                                    ResultSet rsKat = connKat.createStatement().executeQuery("SELECT id, nama_kategori FROM master_kategori");
                                    while(rsKat.next()) {
                                        out.print("<option value='"+rsKat.getInt("id")+"'>"+rsKat.getString("nama_kategori")+"</option>");
                                    }
                                    rsKat.close(); connKat.close();
                                } catch(Exception ignored) {}
                            %>
                        </select>
                    </div>
                    <div class="col-span-1">
                        <label class="block font-[900] text-black tracking-wider uppercase mb-1 text-sm">WAREHOUSE</label>
                        <select name="id_gudang" class="w-full border-[4px] border-black p-2 font-bold text-black focus:outline-none">
                            <option value="">- NO WAREHOUSE -</option>
                            <%
                                try {
                                    koneksi kGud = new koneksi();
                                    Connection connGud = kGud.bukaKoneksi();
                                    ResultSet rsGud = connGud.createStatement().executeQuery("SELECT id, nama_gudang FROM master_gudang");
                                    while(rsGud.next()) {
                                        out.print("<option value='"+rsGud.getInt("id")+"'>"+rsGud.getString("nama_gudang")+"</option>");
                                    }
                                    rsGud.close(); connGud.close();
                                } catch(Exception ignored) {}
                            %>
                        </select>
                    </div>

                    <div class="col-span-2">
                        <label class="block font-[900] text-black tracking-wider uppercase mb-1 text-sm">IMAGE URL</label>
                        <input type="text" name="image_url" class="w-full border-[4px] border-black p-2 font-bold text-black focus:outline-none">
                    </div>
                    
                    <div class="col-span-2">
                        <label class="block font-[900] text-black tracking-wider uppercase mb-1 text-sm">DESCRIPTION</label>
                        <textarea name="deskripsi" class="w-full border-[4px] border-black p-2 font-bold text-black focus:outline-none h-16"></textarea>
                    </div>

                    <div class="col-span-2 flex items-center gap-4 mt-2">
                        <button type="submit" class="bg-[#3498DB] border-[4px] border-black px-8 py-3 font-[900] text-white tracking-wider uppercase brutal-btn-shadow hover:bg-blue-600 transition-colors flex-1 text-center">
                            SAVE PRODUCT
                        </button>
                        <button type="button" onclick="document.getElementById('addModal').classList.add('hidden')" class="bg-white border-[4px] border-black px-8 py-3 font-[900] text-black tracking-wider uppercase brutal-btn-shadow hover:bg-gray-100 transition-colors">
                            CANCEL
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- Modal Edit Item -->
    <div id="editModal" class="fixed inset-0 bg-black bg-opacity-50 z-50 hidden flex items-center justify-center p-4">
        <div class="bg-black p-3 w-full max-w-3xl brutal-shadow">
            <div class="bg-white border-[4px] border-black p-8 relative max-h-[90vh] overflow-y-auto">
                <h3 class="font-[900] text-2xl uppercase tracking-tighter mb-6 text-white bg-black inline-block absolute -top-8 -left-3 px-4 py-2">EDIT ITEM</h3>
                
                <form action="products.jsp?action=edit" method="POST" class="grid grid-cols-2 gap-4 mt-6">
                    <input type="hidden" name="id" id="edit_id">
                    <div class="col-span-2 sm:col-span-1">
                        <label class="block font-[900] text-black tracking-wider uppercase mb-1 text-sm">PRODUCT NAME</label>
                        <input type="text" name="nama_produk" id="edit_nama" required class="w-full border-[4px] border-black p-2 font-bold text-black focus:outline-none">
                    </div>
                    <div class="col-span-2 sm:col-span-1">
                        <label class="block font-[900] text-black tracking-wider uppercase mb-1 text-sm">BRAND / MERK</label>
                        <input type="text" name="merk" id="edit_merk" class="w-full border-[4px] border-black p-2 font-bold text-black focus:outline-none">
                    </div>
                    
                    <div class="col-span-2 sm:col-span-1">
                        <label class="block font-[900] text-black tracking-wider uppercase mb-1 text-sm">BUYING PRICE (IDR)</label>
                        <input type="number" name="harga_beli" id="edit_harga_beli" class="w-full border-[4px] border-black p-2 font-bold text-black focus:outline-none">
                    </div>
                    <div class="col-span-2 sm:col-span-1">
                        <label class="block font-[900] text-black tracking-wider uppercase mb-1 text-sm">SELLING PRICE (IDR)</label>
                        <input type="number" name="harga_jual" id="edit_harga_jual" required class="w-full border-[4px] border-black p-2 font-bold text-black focus:outline-none">
                    </div>

                    <div class="col-span-1">
                        <label class="block font-[900] text-black tracking-wider uppercase mb-1 text-sm">AVAILABLE STOCK</label>
                        <input type="number" name="stok" id="edit_stok" required class="w-full border-[4px] border-black p-2 font-bold text-black focus:outline-none">
                    </div>
                    <div class="col-span-1">
                        <label class="block font-[900] text-black tracking-wider uppercase mb-1 text-sm">SIZE / UNIT</label>
                        <select name="id_ukuran" id="edit_ukuran" class="w-full border-[4px] border-black p-2 font-bold text-black focus:outline-none">
                            <option value="">- SELECT SIZE -</option>
                            <%
                                try {
                                    koneksi kUku2 = new koneksi();
                                    Connection connUku2 = kUku2.bukaKoneksi();
                                    ResultSet rsUku2 = connUku2.createStatement().executeQuery("SELECT id, nama_ukuran FROM master_ukuran");
                                    while(rsUku2.next()) {
                                        out.print("<option value='"+rsUku2.getInt("id")+"'>"+rsUku2.getString("nama_ukuran")+"</option>");
                                    }
                                    rsUku2.close(); connUku2.close();
                                } catch(Exception ignored) {}
                            %>
                        </select>
                    </div>

                    <div class="col-span-1">
                        <label class="block font-[900] text-black tracking-wider uppercase mb-1 text-sm">CATEGORY</label>
                        <select name="id_kategori" id="edit_kategori" required class="w-full border-[4px] border-black p-2 font-bold text-black focus:outline-none">
                            <option value="">- SELECT CATEGORY -</option>
                            <%
                                try {
                                    koneksi kKat3 = new koneksi();
                                    Connection connKat3 = kKat3.bukaKoneksi();
                                    ResultSet rsKat3 = connKat3.createStatement().executeQuery("SELECT id, nama_kategori FROM master_kategori");
                                    while(rsKat3.next()) {
                                        out.print("<option value='"+rsKat3.getInt("id")+"'>"+rsKat3.getString("nama_kategori")+"</option>");
                                    }
                                    rsKat3.close(); connKat3.close();
                                } catch(Exception ignored) {}
                            %>
                        </select>
                    </div>
                    <div class="col-span-1">
                        <label class="block font-[900] text-black tracking-wider uppercase mb-1 text-sm">WAREHOUSE</label>
                        <select name="id_gudang" id="edit_gudang" class="w-full border-[4px] border-black p-2 font-bold text-black focus:outline-none">
                            <option value="">- NO WAREHOUSE -</option>
                            <%
                                try {
                                    koneksi kGud2 = new koneksi();
                                    Connection connGud2 = kGud2.bukaKoneksi();
                                    ResultSet rsGud2 = connGud2.createStatement().executeQuery("SELECT id, nama_gudang FROM master_gudang");
                                    while(rsGud2.next()) {
                                        out.print("<option value='"+rsGud2.getInt("id")+"'>"+rsGud2.getString("nama_gudang")+"</option>");
                                    }
                                    rsGud2.close(); connGud2.close();
                                } catch(Exception ignored) {}
                            %>
                        </select>
                    </div>
                    
                    <div class="col-span-2">
                        <label class="block font-[900] text-black tracking-wider uppercase mb-1 text-sm">IMAGE URL</label>
                        <input type="text" name="image_url" id="edit_img" class="w-full border-[4px] border-black p-2 font-bold text-black focus:outline-none">
                    </div>
                    
                    <div class="col-span-2">
                        <label class="block font-[900] text-black tracking-wider uppercase mb-1 text-sm">DESCRIPTION</label>
                        <textarea name="deskripsi" id="edit_desc" class="w-full border-[4px] border-black p-2 font-bold text-black focus:outline-none h-16"></textarea>
                    </div>

                    <div class="col-span-2 flex items-center gap-4 mt-2">
                        <button type="submit" class="bg-[#FACC15] border-[4px] border-black px-8 py-3 font-[900] text-black tracking-wider uppercase brutal-btn-shadow hover:bg-yellow-400 transition-colors flex-1 text-center">
                            UPDATE PRODUCT
                        </button>
                        <button type="button" onclick="document.getElementById('editModal').classList.add('hidden')" class="bg-white border-[4px] border-black px-8 py-3 font-[900] text-black tracking-wider uppercase brutal-btn-shadow hover:bg-gray-100 transition-colors">
                            CANCEL
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <script>
        function openEditProduct(id, nama, merk, hargaBeli, hargaJual, stok, desc, img, kat, gudang, ukuran) {
            document.getElementById('edit_id').value = id;
            document.getElementById('edit_nama').value = nama;
            document.getElementById('edit_merk').value = merk !== '-' ? merk : '';
            document.getElementById('edit_harga_beli').value = hargaBeli;
            document.getElementById('edit_harga_jual').value = hargaJual;
            document.getElementById('edit_stok').value = stok;
            document.getElementById('edit_desc').value = desc;
            document.getElementById('edit_img').value = img;
            document.getElementById('edit_kategori').value = kat;
            document.getElementById('edit_gudang').value = gudang;
            document.getElementById('edit_ukuran').value = ukuran;
            document.getElementById('editModal').classList.remove('hidden');
        }

        function searchProduct() {
            let input = document.getElementById("searchInput").value.toUpperCase();
            let table = document.getElementById("productTable");
            let tr = table.getElementsByTagName("tr");

            for (let i = 1; i < tr.length; i++) {
                let tdName = tr[i].getElementsByTagName("td")[1];
                let tdBrand = tr[i].getElementsByTagName("td")[2];
                if (tdName || tdBrand) {
                    let nameVal = tdName.textContent || tdName.innerText;
                    let brandVal = tdBrand.textContent || tdBrand.innerText;
                    if (nameVal.toUpperCase().indexOf(input) > -1 || brandVal.toUpperCase().indexOf(input) > -1) {
                        tr[i].style.display = "";
                    } else {
                        tr[i].style.display = "none";
                    }
                }
            }
        }
    </script>
</body>
</html>
