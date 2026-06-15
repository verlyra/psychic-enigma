<%@page import="jdbc.koneksi"%>
<%@page import="java.sql.*"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    if(session.getAttribute("user_id") == null || !"admin".equals(session.getAttribute("role"))) {
        response.sendRedirect("login.jsp");
        return;
    }
    
    int totalProducts = 0;
    int totalUsers = 0;
    int totalGudang = 0;
    int totalKategori = 0;

    try {
        koneksi k = new koneksi();
        Connection conn = k.bukaKoneksi();
        if (conn != null) {
            Statement stmt = conn.createStatement();
            ResultSet rs1 = stmt.executeQuery("SELECT COUNT(*) FROM master_product");
            if(rs1.next()) totalProducts = rs1.getInt(1);
            rs1.close();
            
            ResultSet rs2 = stmt.executeQuery("SELECT COUNT(*) FROM master_user");
            if(rs2.next()) totalUsers = rs2.getInt(1);
            rs2.close();
            
            ResultSet rs3 = stmt.executeQuery("SELECT COUNT(*) FROM master_gudang");
            if(rs3.next()) totalGudang = rs3.getInt(1);
            rs3.close();
            
            try {
                ResultSet rs4 = stmt.executeQuery("SELECT COUNT(*) FROM master_kategori");
                if(rs4.next()) totalKategori = rs4.getInt(1);
                rs4.close();
            } catch(Exception ignored) { }
            
            stmt.close();
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
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;700;900&display=swap" rel="stylesheet">
    <style> 
        body { font-family: 'Inter', sans-serif; background-color: #e5e7eb; } 
        .brutal-shadow { box-shadow: 8px 8px 0px 0px rgba(0,0,0,1); }
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
                <a href="dashboard.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase bg-[#FACC15] text-black">Dashboard</a>
                <a href="products.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">INVENTORY</a>
                <a href="kategori.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">MASTER KATEGORI</a>
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
        <h2 class="text-4xl font-[900] text-black tracking-tight uppercase mb-8">OVERVIEW</h2>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
            <!-- Card 1 -->
            <div class="bg-white border-[4px] border-black p-6 brutal-shadow flex flex-col items-center text-center">
                <h3 class="text-xl font-[900] uppercase tracking-wider mb-2">TOTAL ITEMS</h3>
                <p class="text-6xl font-black text-[#FACC15] drop-shadow-[2px_2px_0px_rgba(0,0,0,1)]"><%= totalProducts %></p>
            </div>
            
            <!-- Card 2 -->
            <div class="bg-white border-[4px] border-black p-6 brutal-shadow flex flex-col items-center text-center">
                <h3 class="text-xl font-[900] uppercase tracking-wider mb-2">TOTAL USERS</h3>
                <p class="text-6xl font-black text-[#3498DB] drop-shadow-[2px_2px_0px_rgba(0,0,0,1)]"><%= totalUsers %></p>
            </div>

            <!-- Card 3 -->
            <div class="bg-white border-[4px] border-black p-6 brutal-shadow flex flex-col items-center text-center">
                <h3 class="text-xl font-[900] uppercase tracking-wider mb-2">TOTAL GUDANG</h3>
                <p class="text-6xl font-black text-[#4ADE80] drop-shadow-[2px_2px_0px_rgba(0,0,0,1)]"><%= totalGudang %></p>
            </div>
            
            <!-- Card 4 -->
            <div class="bg-white border-[4px] border-black p-6 brutal-shadow flex flex-col items-center text-center">
                <h3 class="text-xl font-[900] uppercase tracking-wider mb-2">TOTAL KATEGORI</h3>
                <p class="text-6xl font-black text-[#F97316] drop-shadow-[2px_2px_0px_rgba(0,0,0,1)]"><%= totalKategori %></p>
            </div>
        </div>

        <p class="absolute bottom-4 right-10 font-bold text-gray-400 text-sm">Developed by Dandy & Verly</p>
    </main>

</body>
</html>
