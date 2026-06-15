<%@page import="jdbc.koneksi"%>
<%@page import="java.sql.*"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    if(session.getAttribute("user_id") == null || !"admin".equals(session.getAttribute("role"))) {
        response.sendRedirect("index.jsp");
        return;
    }

    String action = request.getParameter("action");
    if("edit".equals(action) && "POST".equalsIgnoreCase(request.getMethod())) {
        try {
            koneksi k = new koneksi();
            Connection conn = k.bukaKoneksi();
            int id = Integer.parseInt(request.getParameter("id"));
            String roleUpdate = request.getParameter("role");
            
            // Prevent changing own role if that's a requirement, but let's just allow it or keep it simple
            if(session.getAttribute("user_id").toString().equals(String.valueOf(id))) {
                roleUpdate = "admin"; // Force admin if editing self
            }
            
            String sql = "UPDATE master_user SET nama_lengkap=?, username=?, role=? WHERE id=?";
            PreparedStatement pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, request.getParameter("nama_lengkap"));
            pstmt.setString(2, request.getParameter("username"));
            pstmt.setString(3, roleUpdate);
            pstmt.setInt(4, id);
            pstmt.executeUpdate();
            pstmt.close();
            conn.close();
            response.sendRedirect("admin_users.jsp");
            return;
        } catch(Exception e) { out.println("Error: " + e.getMessage()); }
    } else if("delete".equals(action)) {
         try {
            koneksi k = new koneksi();
            Connection conn = k.bukaKoneksi();
            int id = Integer.parseInt(request.getParameter("id"));
            if(!session.getAttribute("user_id").toString().equals(String.valueOf(id))) {
                PreparedStatement pstmt = conn.prepareStatement("DELETE FROM master_user WHERE id = ?");
                pstmt.setInt(1, id);
                pstmt.executeUpdate();
                pstmt.close();
            }
            conn.close();
            response.sendRedirect("admin_users.jsp");
            return;
        } catch(Exception e) { out.println("Error: " + e.getMessage()); }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Master Users - VEND.IO Admin</title>
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
                <a href="admin_dashboard.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">Dashboard</a>
                <a href="admin_products.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">INVENTORY</a>
                <a href="admin_kategori.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">MASTER KATEGORI</a>
                <a href="admin_users.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase bg-[#FACC15] text-black">MASTER USER</a>
                <a href="admin_gudang.jsp" class="px-6 py-4 font-[900] tracking-wider uppercase hover:bg-gray-800 transition-colors">MASTER GUDANG</a>
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
        <h2 class="text-4xl font-[900] text-black tracking-tight uppercase mb-8">USERS</h2>

        <div class="bg-black p-4 w-full brutal-shadow flex-1 flex flex-col">
            <div class="bg-white border-[4px] border-black flex-1 p-6 relative flex flex-col">
                <h3 class="font-[900] text-2xl uppercase tracking-tighter mb-6 text-white bg-black inline-block relative -top-12 -left-2 px-4 pb-0 pt-2">MASTER USERS</h3>
                
                <table class="w-full text-center -mt-8 mb-auto">
                    <thead>
                        <tr class="border-b-[4px] border-black">
                            <th class="py-3 font-[900] text-black uppercase tracking-wider text-center">USERNAME</th>
                            <th class="py-3 font-[900] text-black uppercase tracking-wider text-center">FULL NAME</th>
                            <th class="py-3 font-[900] text-black uppercase tracking-wider text-center">ROLE</th>
                            <th class="py-3 font-[900] text-black uppercase tracking-wider text-center">ACTION</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                            try {
                                koneksi k = new koneksi();
                                Connection conn = k.bukaKoneksi();
                                Statement stmt = conn.createStatement();
                                ResultSet rs = stmt.executeQuery("SELECT * FROM master_user ORDER BY id ASC");
                                String myId = session.getAttribute("user_id").toString();
                                
                                while(rs.next()) {
                                    String role = rs.getString("role");
                                    if(role == null) role = "customer";
                                    boolean isMe = myId.equals(String.valueOf(rs.getInt("id")));
                        %>
                        <tr class="font-bold border-b border-gray-200">
                            <td class="py-4 uppercase"><%= rs.getString("username") %></td>
                            <td class="py-4 uppercase"><%= rs.getString("nama_lengkap") %></td>
                            <td class="py-4 uppercase"><%= role %></td>
                            <td class="py-4">
                                <a href="javascript:void(0)" onclick="openEditUser(<%= rs.getInt("id") %>, '<%= rs.getString("nama_lengkap").replace("'", "\\'") %>', '<%= rs.getString("username").replace("'", "\\'") %>', '<%= role %>')" class="text-[#3498DB] font-[900] uppercase text-sm">EDIT</a>
                                <% if(!isMe) { %>
                                    <span class="text-black font-black mx-1">|</span>
                                    <a href="admin_users.jsp?action=delete&id=<%= rs.getInt("id") %>" class="text-red-500 hover:text-red-700 font-[900] uppercase text-sm" onclick="return confirm('Hapus user ini?');">DELETE</a>
                                <% } %>
                            </td>
                        </tr>
                        <%      }
                                rs.close(); stmt.close(); conn.close();
                            } catch(Exception e) { out.println("<tr><td colspan='4'>Error: " + e.getMessage() + "</td></tr>"); }
                        %>
                    </tbody>
                </table>

                <div class="flex justify-end mt-8">
                    <a href="register.jsp" class="bg-[#FACC15] border-[4px] border-black px-6 py-3 font-[900] text-black tracking-wider uppercase brutal-btn-shadow hover:bg-yellow-400 transition-colors inline-block text-center cursor-pointer">
                        + ADD USER
                    </a>
                </div>
            </div>
        </div>

        <p class="absolute bottom-4 right-10 font-bold text-gray-400 text-sm">Developed by Dandy & Verly</p>
    </main>

    <!-- Modal Edit User -->
    <div id="editModal" class="fixed inset-0 bg-black bg-opacity-50 z-50 hidden flex items-center justify-center p-4">
        <div class="bg-black p-3 w-full max-w-lg brutal-shadow">
            <div class="bg-white border-[4px] border-black p-8 relative">
                <h3 class="font-[900] text-2xl uppercase tracking-tighter mb-6 text-white bg-black inline-block absolute -top-8 -left-3 px-4 py-2">EDIT USER</h3>
                
                <form action="admin_users.jsp?action=edit" method="POST" class="grid grid-cols-1 gap-6 mt-6">
                    <input type="hidden" name="id" id="edit_id">
                    <div>
                        <label class="block font-[900] text-black tracking-wider uppercase mb-1">FULL NAME</label>
                        <input type="text" name="nama_lengkap" id="edit_nama" required class="w-full border-[4px] border-black p-3 font-bold text-black focus:outline-none">
                    </div>
                    <div>
                        <label class="block font-[900] text-black tracking-wider uppercase mb-1">USERNAME</label>
                        <input type="text" name="username" id="edit_username" required class="w-full border-[4px] border-black p-3 font-bold text-black focus:outline-none">
                    </div>
                    <div>
                        <label class="block font-[900] text-black tracking-wider uppercase mb-1">ROLE</label>
                        <select name="role" id="edit_role" class="w-full border-[4px] border-black p-3 font-bold text-black focus:outline-none">
                            <option value="customer">CUSTOMER</option>
                            <option value="admin">ADMIN</option>
                        </select>
                    </div>

                    <div class="flex items-center gap-4 mt-4">
                        <button type="submit" class="bg-[#FACC15] border-[4px] border-black px-8 py-3 font-[900] text-black tracking-wider uppercase brutal-btn-shadow hover:bg-yellow-400 transition-colors flex-1 text-center">
                            UPDATE USER
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
        function openEditUser(id, nama, username, role) {
            document.getElementById('edit_id').value = id;
            document.getElementById('edit_nama').value = nama;
            document.getElementById('edit_username').value = username;
            document.getElementById('edit_role').value = role;
            document.getElementById('editModal').classList.remove('hidden');
        }
    </script>
</body>
</html>
