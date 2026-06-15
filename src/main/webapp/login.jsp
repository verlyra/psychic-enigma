<%-- 
    Document   : index
    Created on : Apr 14, 2026, 6:40:25â€¯PM
    Author     : verly
--%>

<%@page import="jdbc.koneksi"%>
<%@page import="java.sql.*"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>

<%!
    private String getParam(HttpServletRequest request, String name) {
        String value = request.getParameter(name);
        return (value == null) ? "" : value;
    }
%>

<%
    String errorMsg = "";
    String action = getParam(request, "action");

    if ("login".equals(action) && "POST".equalsIgnoreCase(request.getMethod())) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        String userParam = getParam(request, "username");
        String passParam = getParam(request, "password");

        try {
            koneksi k = new koneksi();
            conn = k.bukaKoneksi();
            
            if (conn == null) {
                throw new SQLException("Gagal membuat koneksi ke database.");
            }

            String sql = "SELECT * FROM master_user WHERE username = ? AND kata_sandi = ?";
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, userParam);
            pstmt.setString(2, passParam); 
            
            rs = pstmt.executeQuery();

            if (rs.next()) {
                String role = rs.getString("role");
                if(role == null) role = "customer"; // Default fallback

                session.setAttribute("user_id", rs.getString("id"));
                session.setAttribute("username", rs.getString("username"));
                session.setAttribute("nama_lengkap", rs.getString("nama_lengkap"));
                session.setAttribute("role", role);
                
                if ("admin".equals(role)) {
                    response.sendRedirect("admin/dashboard.jsp"); 
                } else {
                    response.sendRedirect("index.jsp"); 
                }
                return;
            } else {
                errorMsg = "Username atau Password salah!";
            }
        } catch (Exception e) {
            errorMsg = "Error: " + e.getMessage();
        } finally {
            if (rs != null) rs.close();
            if (pstmt != null) pstmt.close();
            if (conn != null) conn.close();
        }
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>VEND.IO - Login</title>
    <!-- Tailwind CDN -->
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;700;900&display=swap" rel="stylesheet">
    <style>
        body {
            font-family: 'Inter', sans-serif;
            background-color: #e5e7eb; /* Light Gray */
        }
        .neubrutalism-card {
            box-shadow: 8px 8px 0px 0px rgba(0,0,0,1);
        }
        .neubrutalism-btn {
            box-shadow: 4px 4px 0px 0px rgba(0,0,0,1);
        }
        .neubrutalism-btn:active {
            box-shadow: 0px 0px 0px 0px rgba(0,0,0,1);
            transform: translate(4px, 4px);
        }
    </style>
</head>
<body class="min-h-screen flex items-center justify-center p-4">

    <div class="bg-white border-[4px] border-black p-10 w-full max-w-[400px] neubrutalism-card">
        
        <!-- Logo Container -->
        <div class="flex flex-col items-center mb-10">
            <div class="bg-[#FACC15] border-[4px] border-black p-3 mb-6">
                <!-- Icon Keranjang Belanja -->
                <svg xmlns="http://www.w3.org/2000/svg" width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="black" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="9" cy="21" r="1"></circle>
                    <circle cx="20" cy="21" r="1"></circle>
                    <path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"></path>
                </svg>
            </div>
            
            <h1 class="text-5xl font-[900] italic tracking-tighter text-black mb-1">VEND.IO</h1>
            <div class="h-3 w-48 bg-black mt-1"></div> <!-- Garis bawah tebal -->
        </div>

        <!-- Error Message -->
        <% if (!errorMsg.isEmpty()) { %>
            <div class="bg-red-200 border-[3px] border-black p-3 mb-6 text-sm font-bold text-center text-black">
                <%= errorMsg %>
            </div>
        <% } %>

        <!-- Login Form -->
        <form action="login.jsp?action=login" method="POST" class="space-y-6">
            <div>
                <label class="block text-sm font-black tracking-widest uppercase text-black mb-2">USERNAME</label>
                <input type="text" name="username" placeholder="Enter username" required
                    class="w-full border-[3px] border-black p-3 font-bold text-black focus:outline-none placeholder:text-gray-300">
            </div>

            <div>
                <label class="block text-sm font-black tracking-widest uppercase text-black mb-2">PASSWORD</label>
                <input type="password" name="password" placeholder="Enter Password" required
                    class="w-full border-[3px] border-black p-3 font-bold text-black focus:outline-none placeholder:text-gray-300">
            </div>

            <button type="submit" 
                class="w-full bg-[#FACC15] border-[4px] border-black p-4 mt-4 text-2xl font-black uppercase tracking-widest text-black hover:bg-yellow-400 transition-all neubrutalism-btn">
                LOGIN
            </button>
        </form>

        <!-- Footer -->
        <div class="mt-10 text-center space-y-2">
            <p class="font-bold text-sm text-gray-400">Developed by Dandy & Verly</p>
            <p class="font-bold text-xs"><a href="register.jsp" class="text-blue-600 underline">Register</a></p>
        </div>
    </div>

</body>
</html>
