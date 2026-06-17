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
    String successMsg = "";
    String action = getParam(request, "action");

    if ("register".equals(action) && "POST".equalsIgnoreCase(request.getMethod())) {
        Connection conn = null;
        PreparedStatement pstmt = null;

        String username = getParam(request, "username");
        String fullName = getParam(request, "nama_lengkap");
        String noTelp = getParam(request, "no_telp");
        String alamat = getParam(request, "alamat");
        String password = getParam(request, "password");
        String confirmPassword = getParam(request, "confirm_password");

        if (!password.equals(confirmPassword)) {
            errorMsg = "Password dan Konfirmasi Password tidak cocok!";
        } else {
            try {
                koneksi k = new koneksi();
                conn = k.bukaKoneksi();
                
                if (conn == null) {
                    throw new SQLException("Gagal membuat koneksi ke database.");
                }

                // Check if username already exists
                String checkSql = "SELECT username FROM master_user WHERE username = ?";
                pstmt = conn.prepareStatement(checkSql);
                pstmt.setString(1, username);
                ResultSet rs = pstmt.executeQuery();
                
                if (rs.next()) {
                    errorMsg = "Username sudah digunakan!";
                    rs.close();
                } else {
                    rs.close();
                    pstmt.close();
                    
                    // Dapatkan ID maksimum saat ini dan tambah 1
                    int newId = 1;
                    String maxIdSql = "SELECT MAX(id) FROM master_user";
                    PreparedStatement pstmtMax = conn.prepareStatement(maxIdSql);
                    ResultSet rsMax = pstmtMax.executeQuery();
                    if (rsMax.next()) {
                        newId = rsMax.getInt(1) + 1;
                    }
                    rsMax.close();
                    pstmtMax.close();

                    // Insert new user with no_telp and alamat
                    String sql = "INSERT INTO master_user (id, username, kata_sandi, nama_lengkap, no_telp, alamat, role) VALUES (?, ?, ?, ?, ?, ?, 'customer')";
                    pstmt = conn.prepareStatement(sql);
                    pstmt.setInt(1, newId);
                    pstmt.setString(2, username);
                    pstmt.setString(3, password);
                    pstmt.setString(4, fullName);
                    pstmt.setString(5, noTelp);
                    pstmt.setString(6, alamat);
                    
                    int rowsInserted = pstmt.executeUpdate();
                    if (rowsInserted > 0) {
                        successMsg = "Registrasi berhasil! Silahkan login.";
                    } else {
                        errorMsg = "Gagal mendaftarkan user baru.";
                    }
                }
            } catch (Exception e) {
                errorMsg = "Error: " + e.getMessage();
            } finally {
                if (pstmt != null) pstmt.close();
                if (conn != null) conn.close();
            }
        }
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>VEND.IO - Register</title>
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

    <div class="bg-white border-[4px] border-black p-10 w-full max-w-[480px] neubrutalism-card">
        
        <!-- Logo Container -->
        <div class="flex flex-col items-center mb-10">
            <div class="bg-[#FACC15] border-[4px] border-black p-3 mb-6">
                <!-- Icon User Add -->
                <svg xmlns="http://www.w3.org/2000/svg" width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="black" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"></path>
                    <circle cx="9" cy="7" r="4"></circle>
                    <line x1="19" y1="8" x2="19" y2="14"></line>
                    <line x1="22" y1="11" x2="16" y2="11"></line>
                </svg>
            </div>
            
            <h1 class="text-3xl font-[900] italic tracking-tighter text-black mb-1">REGISTER</h1>
            <div class="h-3 w-32 bg-black mt-1"></div>
        </div>

        <!-- Messages -->
        <% if (!errorMsg.isEmpty()) { %>
            <div class="bg-red-200 border-[3px] border-black p-3 mb-6 text-sm font-bold text-center text-black">
                <%= errorMsg %>
            </div>
        <% } %>
        <% if (!successMsg.isEmpty()) { %>
            <div class="bg-green-200 border-[3px] border-black p-3 mb-6 text-sm font-bold text-center text-black">
                <%= successMsg %> <br>
                <a href="login.jsp" class="underline font-bold mt-1 inline-block">Ke Halaman Login</a>
            </div>
        <% } %>

        <!-- Register Form -->
        <form action="register.jsp?action=register" method="POST" class="space-y-4">
            <div>
                <label class="block text-sm font-black tracking-widest uppercase text-black mb-2">NAMA LENGKAP</label>
                <input type="text" name="nama_lengkap" placeholder="Masukkan nama lengkap" required
                    class="w-full border-[3px] border-black p-3 font-bold text-black focus:outline-none placeholder:text-gray-300">
            </div>

            <div>
                <label class="block text-sm font-black tracking-widest uppercase text-black mb-2">USERNAME</label>
                <input type="text" name="username" placeholder="Masukkan username" required
                    class="w-full border-[3px] border-black p-3 font-bold text-black focus:outline-none placeholder:text-gray-300">
            </div>

            <div>
                <label class="block text-sm font-black tracking-widest uppercase text-black mb-2">PASSWORD</label>
                <input type="password" name="password" placeholder="Masukkan password" required
                    class="w-full border-[3px] border-black p-3 font-bold text-black focus:outline-none placeholder:text-gray-300">
            </div>

            <div>
                <label class="block text-sm font-black tracking-widest uppercase text-black mb-2">KONFIRMASI PASSWORD</label>
                <input type="password" name="confirm_password" placeholder="Ulangi password" required
                    class="w-full border-[3px] border-black p-3 font-bold text-black focus:outline-none placeholder:text-gray-300">
            </div>

            <div>
                <label class="block text-sm font-black tracking-widest uppercase text-black mb-2">NO. TELEPON</label>
                <input type="tel" name="no_telp" placeholder="Contoh: 08123456789"
                    class="w-full border-[3px] border-black p-3 font-bold text-black focus:outline-none placeholder:text-gray-300">
            </div>

            <div>
                <label class="block text-sm font-black tracking-widest uppercase text-black mb-2">ALAMAT</label>
                <textarea name="alamat" placeholder="Masukkan alamat lengkap Anda" rows="3"
                    class="w-full border-[3px] border-black p-3 font-bold text-black focus:outline-none placeholder:text-gray-300 resize-none"></textarea>
            </div>

            <button type="submit" 
                class="w-full bg-[#4ADE80] border-[4px] border-black p-4 mt-6 text-2xl font-black uppercase tracking-widest text-black hover:bg-green-500 transition-all neubrutalism-btn">
                DAFTAR
            </button>
        </form>

        <!-- Footer / Link Login -->
        <div class="mt-8 text-center">
            <p class="font-bold text-sm">Sudah punya akun? <a href="login.jsp" class="text-blue-600 underline decoration-2">Login di sini</a></p>
        </div>
    </div>

</body>
</html>
