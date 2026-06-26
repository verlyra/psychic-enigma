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
            String sql = "INSERT INTO master_gudang (nama_gudang, lokasi, nama_pic, no_telp) VALUES (?, ?, ?, ?)";
            PreparedStatement pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, request.getParameter("nama_gudang"));
            pstmt.setString(2, request.getParameter("lokasi"));
            pstmt.setString(3, request.getParameter("nama_pic"));
            pstmt.setString(4, request.getParameter("no_telp"));
            pstmt.executeUpdate();
            pstmt.close();
            conn.close();
            response.sendRedirect("gudang.jsp");
            return;
        } catch(Exception e) { out.println("Error: " + e.getMessage()); }
    } else if("edit".equals(action) && "POST".equalsIgnoreCase(request.getMethod())) {
        try {
            koneksi k = new koneksi();
            Connection conn = k.bukaKoneksi();
            String sql = "UPDATE master_gudang SET nama_gudang=?, lokasi=?, nama_pic=?, no_telp=? WHERE id=?";
            PreparedStatement pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, request.getParameter("nama_gudang"));
            pstmt.setString(2, request.getParameter("lokasi"));
            pstmt.setString(3, request.getParameter("nama_pic"));
            pstmt.setString(4, request.getParameter("no_telp"));
            pstmt.setInt(5, Integer.parseInt(request.getParameter("id")));
            pstmt.executeUpdate();
            pstmt.close();
            conn.close();
            response.sendRedirect("gudang.jsp");
            return;
        } catch(Exception e) { out.println("Error: " + e.getMessage()); }
    } else if("delete".equals(action)) {
        try {
            koneksi k = new koneksi();
            Connection conn = k.bukaKoneksi();
            PreparedStatement pstmt = conn.prepareStatement("DELETE FROM master_gudang WHERE id = ?");
            pstmt.setInt(1, Integer.parseInt(request.getParameter("id")));
            pstmt.executeUpdate();
            pstmt.close();
            conn.close();
            response.sendRedirect("gudang.jsp");
            return;
        } catch(Exception e) { out.println("Error: " + e.getMessage()); }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Master Gudang - VEND.IO Admin</title>
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
                <a href="pesanan.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">PESANAN</a>
                <a href="pengiriman.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">PENGIRIMAN</a>
                <a href="diskon.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">DISKON & PROMO</a>
                <a href="products.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">INVENTORY</a>
                <a href="kategori.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">MASTER KATEGORI</a>
                <a href="ukuran.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">MASTER UKURAN</a>
                <a href="users.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">MASTER USER</a>
                <a href="gudang.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase bg-[#FACC15] text-black">MASTER GUDANG</a>
                <a href="laporan.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">LAPORAN PENJUALAN</a>
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
        <h2 class="text-4xl font-[900] text-black tracking-tight uppercase mb-8">WAREHOUSE</h2>

        <div class="bg-black p-4 w-full brutal-shadow flex-1 flex flex-col">
            <div class="bg-white border-[4px] border-black flex-1 p-6 relative flex flex-col">
                <h3 class="font-[900] text-2xl uppercase tracking-tighter mb-6 text-white bg-black inline-block relative -top-12 -left-2 px-4 pb-0 pt-2">MASTER GUDANG</h3>
                
                <div class="-mt-8 mb-4">
                    <input type="text" id="searchInput" onkeyup="searchTable()" placeholder="SEARCH BY NAME, PIC, OR PHONE..." class="w-full border-[4px] border-black p-3 font-[900] text-black tracking-wider uppercase focus:outline-none">
                </div>

                <table class="w-full text-left mb-auto" id="dataTable">
                    <thead>
                        <tr class="border-b-[4px] border-black">
                            <th class="py-3 font-[900] text-black uppercase tracking-wider w-16">ID</th>
                            <th class="py-3 font-[900] text-black uppercase tracking-wider">WAREHOUSE</th>
                            <th class="py-3 font-[900] text-black uppercase tracking-wider">PIC</th>
                            <th class="py-3 font-[900] text-black uppercase tracking-wider">PHONE</th>
                            <th class="py-3 font-[900] text-black uppercase tracking-wider">LOCATION</th>
                            <th class="py-3 font-[900] text-black uppercase tracking-wider text-right whitespace-nowrap">ACTION</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                            try {
                                koneksi k = new koneksi();
                                Connection conn = k.bukaKoneksi();
                                Statement stmt = conn.createStatement();
                                ResultSet rs = stmt.executeQuery("SELECT * FROM master_gudang ORDER BY id DESC");
                                while(rs.next()) {
                            String pic = rs.getString("nama_pic") != null ? rs.getString("nama_pic") : "-";
                            String telp = rs.getString("no_telp") != null ? rs.getString("no_telp") : "-";
                        %>
                        <tr class="font-bold border-b border-gray-200">
                            <td class="py-4"><%= rs.getInt("id") %></td>
                            <td class="py-4 uppercase"><%= rs.getString("nama_gudang") %></td>
                            <td class="py-4 uppercase"><%= pic %></td>
                            <td class="py-4 uppercase"><%= telp %></td>
                            <td class="py-4 uppercase"><%= rs.getString("lokasi") %></td>
                            <td class="py-4 text-right whitespace-nowrap">
                                <a href="gudang.jsp?action=info&id=<%= rs.getInt("id") %>" class="text-[#4ADE80] font-[900] uppercase text-sm">INFO</a>
                                <span class="text-black font-black mx-1">|</span>
                                <a href="javascript:void(0)" onclick="openEditGudang(<%= rs.getInt("id") %>, '<%= rs.getString("nama_gudang").replace("'", "\\'") %>', '<%= pic.replace("'", "\\'") %>', '<%= telp.replace("'", "\\'") %>', '<%= rs.getString("lokasi").replace("'", "\\'").replace("\n", " ") %>')" class="text-[#3498DB] font-[900] uppercase text-sm">EDIT</a>
                                <span class="text-black font-black mx-1">|</span>
                                <a href="gudang.jsp?action=delete&id=<%= rs.getInt("id") %>" class="text-red-500 hover:text-red-700 font-[900] uppercase text-sm" onclick="return confirm('Hapus gudang ini?');">DELETE</a>
                            </td>
                        </tr>
                        <%      }
                                rs.close(); stmt.close(); conn.close();
                            } catch(Exception e) { out.println("<tr><td colspan='4'>Error: " + e.getMessage() + "</td></tr>"); }
                        %>
                    </tbody>
                </table>

                <div class="flex justify-end mt-8">
                    <button onclick="document.getElementById('addModal').classList.remove('hidden')" class="bg-[#3498DB] border-[4px] border-black px-6 py-3 font-[900] text-white tracking-wider uppercase brutal-btn-shadow hover:bg-blue-600 transition-colors">
                        + ADD WAREHOUSE
                    </button>
                </div>
            </div>
        </div>

        <p class="absolute bottom-4 right-10 font-bold text-gray-400 text-sm">Developed by Dandy & Verly</p>
    </main>

    <!-- Modal Add Gudang -->
    <div id="addModal" class="fixed inset-0 bg-black bg-opacity-50 z-50 hidden flex items-center justify-center p-4">
        <!-- brutalist modal -->
        <div class="bg-black p-3 w-full max-w-lg brutal-shadow">
            <div class="bg-white border-[4px] border-black p-8 relative">
                <h3 class="font-[900] text-2xl uppercase tracking-tighter mb-6 text-white bg-black inline-block absolute -top-8 -left-3 px-4 py-2">ADD NEW WAREHOUSE</h3>
                
                <form action="gudang.jsp?action=add" method="POST" class="grid grid-cols-1 gap-6 mt-6">
                    <div>
                        <label class="block font-[900] text-black tracking-wider uppercase mb-1">WAREHOUSE NAME</label>
                        <input type="text" name="nama_gudang" required class="w-full border-[4px] border-black p-3 font-bold text-black focus:outline-none">
                    </div>
                    <div class="grid grid-cols-2 gap-6">
                        <div>
                            <label class="block font-[900] text-black tracking-wider uppercase mb-1">PIC NAME</label>
                            <input type="text" name="nama_pic" class="w-full border-[4px] border-black p-3 font-bold text-black focus:outline-none">
                        </div>
                        <div>
                            <label class="block font-[900] text-black tracking-wider uppercase mb-1">PHONE NUMBER</label>
                            <input type="text" name="no_telp" class="w-full border-[4px] border-black p-3 font-bold text-black focus:outline-none">
                        </div>
                    </div>
                    <div>
                        <label class="block font-[900] text-black tracking-wider uppercase mb-1">LOCATION / ADDRESS</label>
                        <textarea name="lokasi" required class="w-full border-[4px] border-black p-3 font-bold text-black focus:outline-none h-24"></textarea>
                    </div>

                    <div class="flex items-center gap-4 mt-4">
                        <button type="submit" class="bg-[#3498DB] border-[4px] border-black px-8 py-3 font-[900] text-white tracking-wider uppercase brutal-btn-shadow hover:bg-blue-600 transition-colors flex-1 text-center">
                            SAVE WAREHOUSE
                        </button>
                        <button type="button" onclick="document.getElementById('addModal').classList.add('hidden')" class="bg-white border-[4px] border-black px-8 py-3 font-[900] text-black tracking-wider uppercase brutal-btn-shadow hover:bg-gray-100 transition-colors">
                            CANCEL
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- Modal Edit Gudang -->
    <div id="editModal" class="fixed inset-0 bg-black bg-opacity-50 z-50 hidden flex items-center justify-center p-4">
        <!-- brutalist modal -->
        <div class="bg-black p-3 w-full max-w-lg brutal-shadow">
            <div class="bg-white border-[4px] border-black p-8 relative">
                <h3 class="font-[900] text-2xl uppercase tracking-tighter mb-6 text-white bg-black inline-block absolute -top-8 -left-3 px-4 py-2">EDIT WAREHOUSE</h3>
                
                <form action="gudang.jsp?action=edit" method="POST" class="grid grid-cols-1 gap-6 mt-6">
                    <input type="hidden" name="id" id="edit_id">
                    <div>
                        <label class="block font-[900] text-black tracking-wider uppercase mb-1">WAREHOUSE NAME</label>
                        <input type="text" name="nama_gudang" id="edit_nama" required class="w-full border-[4px] border-black p-3 font-bold text-black focus:outline-none">
                    </div>
                    <div class="grid grid-cols-2 gap-6">
                        <div>
                            <label class="block font-[900] text-black tracking-wider uppercase mb-1">PIC NAME</label>
                            <input type="text" name="nama_pic" id="edit_pic" class="w-full border-[4px] border-black p-3 font-bold text-black focus:outline-none">
                        </div>
                        <div>
                            <label class="block font-[900] text-black tracking-wider uppercase mb-1">PHONE NUMBER</label>
                            <input type="text" name="no_telp" id="edit_telp" class="w-full border-[4px] border-black p-3 font-bold text-black focus:outline-none">
                        </div>
                    </div>
                    <div>
                        <label class="block font-[900] text-black tracking-wider uppercase mb-1">LOCATION / ADDRESS</label>
                        <textarea name="lokasi" id="edit_lokasi" required class="w-full border-[4px] border-black p-3 font-bold text-black focus:outline-none h-24"></textarea>
                    </div>

                    <div class="flex items-center gap-4 mt-4">
                        <button type="submit" class="bg-[#3498DB] border-[4px] border-black px-8 py-3 font-[900] text-white tracking-wider uppercase brutal-btn-shadow hover:bg-blue-600 transition-colors flex-1 text-center">
                            UPDATE WAREHOUSE
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
        function openEditGudang(id, nama, pic, telp, lokasi) {
            document.getElementById('edit_id').value = id;
            document.getElementById('edit_nama').value = nama;
            document.getElementById('edit_pic').value = pic !== '-' ? pic : '';
            document.getElementById('edit_telp').value = telp !== '-' ? telp : '';
            document.getElementById('edit_lokasi').value = lokasi;
            document.getElementById('editModal').classList.remove('hidden');
        }

        function searchTable() {
            let input = document.getElementById("searchInput").value.toUpperCase();
            let table = document.getElementById("dataTable");
            let tr = table.getElementsByTagName("tr");

            for (let i = 1; i < tr.length; i++) {
                let tdName = tr[i].getElementsByTagName("td")[1];
                let tdPic = tr[i].getElementsByTagName("td")[2];
                let tdPhone = tr[i].getElementsByTagName("td")[3];
                
                if (tdName || tdPic || tdPhone) {
                    let textName = tdName.textContent || tdName.innerText;
                    let textPic = tdPic.textContent || tdPic.innerText;
                    let textPhone = tdPhone.textContent || tdPhone.innerText;
                    
                    if (textName.toUpperCase().indexOf(input) > -1 || textPic.toUpperCase().indexOf(input) > -1 || textPhone.toUpperCase().indexOf(input) > -1) {
                        tr[i].style.display = "";
                    } else {
                        tr[i].style.display = "none";
                    }
                }       
            }
        }
    </script>

    <% if("info".equals(action) && request.getParameter("id") != null) { 
        int infoId = Integer.parseInt(request.getParameter("id"));
        String infoNamaGudang = "";
        try {
            koneksi kInfo = new koneksi();
            Connection connInfo = kInfo.bukaKoneksi();
            PreparedStatement pstmtGudang = connInfo.prepareStatement("SELECT nama_gudang FROM master_gudang WHERE id = ?");
            pstmtGudang.setInt(1, infoId);
            ResultSet rsGudang = pstmtGudang.executeQuery();
            if(rsGudang.next()) {
                infoNamaGudang = rsGudang.getString("nama_gudang");
            }
            rsGudang.close();
            pstmtGudang.close();
    %>
    <!-- Modal Info Gudang -->
    <div class="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4">
        <div class="bg-black p-3 w-full max-w-3xl brutal-shadow">
            <div class="bg-white border-[4px] border-black p-8 relative max-h-[80vh] overflow-y-auto">
                <h3 class="font-[900] text-2xl uppercase tracking-tighter mb-6 text-white bg-black inline-block absolute -top-8 -left-3 px-4 py-2">WAREHOUSE INFO</h3>
                
                <div class="mt-6">
                    <p class="font-[900] text-xl text-black tracking-wider uppercase mb-4">GUDANG: <%= infoNamaGudang %></p>
                    
                    <table class="w-full text-left border-collapse">
                        <thead>
                            <tr class="border-b-[4px] border-black">
                                <th class="py-2 font-[900] text-black uppercase tracking-wider">PRODUCT NAME</th>
                                <th class="py-2 font-[900] text-black uppercase tracking-wider">CATEGORY</th>
                                <th class="py-2 font-[900] text-black uppercase tracking-wider text-right">STOCK</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                PreparedStatement pstmtProd = connInfo.prepareStatement("SELECT p.nama_produk, k.nama_kategori, p.stok FROM master_product p LEFT JOIN master_kategori k ON p.id_kategori = k.id WHERE p.id_gudang = ? ORDER BY p.nama_produk ASC");
                                pstmtProd.setInt(1, infoId);
                                ResultSet rsProd = pstmtProd.executeQuery();
                                boolean hasItems = false;
                                while(rsProd.next()) {
                                    hasItems = true;
                                    String kat = rsProd.getString("nama_kategori");
                                    if(kat == null || kat.trim().isEmpty()) kat = "-";
                            %>
                            <tr class="font-bold border-b border-gray-200">
                                <td class="py-3 uppercase"><%= rsProd.getString("nama_produk") %></td>
                                <td class="py-3 uppercase"><%= kat %></td>
                                <td class="py-3 text-right"><%= rsProd.getInt("stok") %> pcs</td>
                            </tr>
                            <%  }
                                rsProd.close();
                                pstmtProd.close();
                                if(!hasItems) {
                            %>
                            <tr>
                                <td colspan="3" class="py-4 text-center font-[900] uppercase text-gray-500">NO ITEMS IN THIS WAREHOUSE</td>
                            </tr>
                            <%  } %>
                        </tbody>
                    </table>
                </div>

                <div class="flex justify-end mt-8">
                    <a href="gudang.jsp" class="bg-white border-[4px] border-black px-8 py-3 font-[900] text-black tracking-wider uppercase brutal-btn-shadow hover:bg-gray-100 transition-colors inline-block">
                        CLOSE
                    </a>
                </div>
            </div>
        </div>
    </div>
    <%
            connInfo.close();
        } catch(Exception e) { out.println("<script>alert('Error loading info: " + e.getMessage() + "');</script>"); }
    } %>
</body>
</html>
