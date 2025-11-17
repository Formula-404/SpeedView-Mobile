# Speedview-Mobile

Setiap balapan **Formula 1** bukan hanya tentang *20 mobil yang berputar di suatu lintasan*.  
Tapi ini tentang kombinasi **pembalap yang memacu batasan**, **tim pemenang adalah tim yang bermain strategi**, dan detail kecil seperti **cuaca** atau **timing pit stop** yang bisa menentukan hasil akhir.

---

**SpeedView** hadir untuk melihat lebih dekat detail-detail itu.  
Tujuannya adalah mengubah **data balapan yang tadinya monoton dan teknis** menjadi **hub interaktif** tempat penggemar, mahasiswa, dan peneliti bisa:

- Menjelajahi balapan lewat ***meetings, sessions, drivers, dan circuits***
- Menganalisis performa lewat **lap times, pengaruh cuaca, dan pit strategies**
- Mempelajari sisi **teknis dari olahraga ini** (*cars, teams, telemetry*)


## Contributor
<table>
    <tr>
        <td align="center">
            <a href="https://github.com/helvenix">
                <img src="https://avatars.githubusercontent.com/u/109453997?v=4" width="80px;" alt="Helven Marica"/>
                <br /><sub><b>Helven Marcia</b></sub>
            </a>
        </td>
        <td align="center">
            <a href="https://github.com/haekalhdn">
                <img src="https://avatars.githubusercontent.com/u/178357458?v=4" width="80px;" alt="Haekal Handrian"/>
                <br /><sub><b>Haekal Handrian</b></sub>
            </a>
        </td>
        <td align="center">
            <a href="https://github.com/puut12">
                <img src="https://avatars.githubusercontent.com/u/198161335?v=4" width="80px;" alt="Putri Hamidah Riyanto"/>
                <br /><sub><b>Putri Hamidah Riyanto</b></sub>
            </a>
        </td>
        <td align="center">
            <a href="https://github.com/nail-nail">
                <img src="https://avatars.githubusercontent.com/u/198184000?v=4" width="80px;" alt="Naila Khadijah"/>
                <br /><sub><b>Naila Khadijah</b></sub>
            </a>
        </td>
        <td align="center">
            <a href="https://github.com/lucidd2712">
                <img src="https://avatars.githubusercontent.com/u/198191346?v=4" width="80px;" alt="Gilang Adjie Saputra"/>
                <br /><sub><b>Gilang Adjie Saputra</b></sub>
            </a>
        </td>
    </tr>
</table>

## Module Overview
<table>
  <tr>
    <th style="width:180px; text-align:left;">Module</th>
    <th style="text-align:left;">Purpose</th>
    <th style="text-align:left;">Developer</th>
  </tr>
  <tr>
    <td><b>User</b></td>
    <td>Authentication, user profiles, and role permissions</td>
    <td>Haekal</td>
  </tr>
  <tr>
    <td><b>Driver</b></td>
    <td>Stores driver details, nationality, and racing statistics</td>
    <td>Gilang</td>
  </tr>
  <tr>
    <td><b>Circuit</b></td>
    <td>Metadata about circuits (name, location, length, turns, layout)</td>
    <td>Putri</td>
  </tr>
  <tr>
    <td><b>Meeting</b></td>
    <td>Represents a Grand Prix weekend (e.g., Monaco GP 2025)</td>
    <td>Putri</td>
  </tr>
  <tr>
    <td><b>Session</b></td>
    <td>Practice sessions, Qualifying, Sprint, and Race data</td>
    <td>Putri</td>
  </tr>
  <tr>
    <td><b>Weather</b></td>
    <td>Environmental conditions (track temperature, rain, wind, humidity)</td>
    <td>Putri</td>
  </tr>
  <tr>
    <td><b>Team</b></td>
    <td>Constructor details, linked with drivers and cars</td>
    <td>Helven</td>
  </tr>
  <tr>
    <td><b>Car</b></td>
    <td>Technical specifications of cars (engine, chassis, season entries)</td>
    <td>Naila</td>
  </tr>
  <tr>
    <td><b>Laps</b></td>
    <td>Lap-by-lap performance data, including timing, sectors, and telemetry</td>
    <td>Gilang</td>
  </tr>
  <tr>
    <td><b>Pit</b></td>
    <td>Pit stop strategies, tire changes, and related time losses</td>
    <td>Gilang</td>
  </tr>
  <tr>
    <td><b>Comparison</b></td>
    <td>Comparison session to compare Driver, Team, Car, Circuit with statistical view</td>
    <td>Helven</td>
  </tr>
</table>

## **User Roles**

### 🧭 **Guest**
- Hanya bisa mengakses halaman dengan mode *read-only*

### 👤 **Login User**
- Bisa **membuat dan menyimpan sesi perbandingan (comparison sessions)**
- Dapat **membagikan sesi** dengan pengguna lain

### 🛠️ **Admin**
- Dapat **mengedit data wiki tertentu**
- Bisa **memoderasi forum** (menghapus postingan)
- Memiliki **alat dan izin manajemen tambahan**


## Penjelasan Alur Integrasi
### Ringkasan Arsitektur
- **Aplikasi web**: Django yang sudah memiliki modul user, driver, car, meeting, dsb lengkap dengan view JSON hasil PTS.
- **Aplikasi mobile**: Flutter dengan Material 3 dan state management ringan menggunakan `Provider`.
- **Hubungan web dan mobile**: Menggunakan `CookieRequest` dari package `pbp_django_auth` sehingga app mobile dapat menjalankan login, menyertakan cookie session, dan mengirim/menarik data JSON. Flutter cukup memanggil endpoint Django yang sudah ada.

### Alur Pengintegrasian dengan Web Service

#### 1. Menyediakan Representasi Data di Django
1. Memastikan setiap modul yang ingin ditampilkan di Flutter memiliki endpoint JSON berformat konsisten (contoh: `/car/json/`, `/car/json/<id>/`, `/meeting/json/`). Endpoint ini berupa view fungsi yang melakukan `serializers.serialize` atau `values()` kemudian dibungkus oleh `JsonResponse`.
2. Membuat view baru yang menerima request `POST` berisi JSON dan mengembalikan status sukses/gagal.
3. Peran (guest, login user, admin) tetap dikontrol oleh Django melalui session sehingga tidak ada perubahan besar di sisi backend.

#### 2. Membawa Definisi Model ke Flutter
1. Dari struktur JSON yang dikirim web service, turunkan kelas model di Flutter. Misal modul Car:
   ```dart
   class Car {
     Car({
       required this.id,
       required this.model,
       required this.brand,
       required this.color,
       this.releaseDate,
     });

     factory Car.fromJson(Map<String, dynamic> json) => Car(
           id: json['id'],
           model: json['model'],
           brand: json['brand'],
           color: json['color'],
           releaseDate: json['release_date'] != null
               ? DateTime.parse(json['release_date'])
               : null,
         );
   }
   ```
2. Membuat fungsi (con: `carFromJson`/`carToJson`) yang digunakan untuk mengonversi antara string JSON dan objek Dart. Penyesuaian hanya berupa nama field agar cocok dengan model SpeedView.

#### 3. Menyiapkan Jalur Komunikasi di Flutter
1. Menambahkan dependency `pbp_django_auth`, `http`, dan `provider` pada `pubspec.yaml`.
2. Wrap aplikasi dengan `Provider` yang menampung `CookieRequest`.
3. Menambahkan beberapa halaman sehingga `CookieRequest` biasanya diteruskan melalui `Consumer<CookieRequest>` atau `context.watch<CookieRequest>()` pada setiap screen agar akses session konsisten.

#### 4. Alur Komunikasi Data
1. **Login**: halaman login Flutter memanggil `request.login('http://HOST/auth/login/', {...})`. Jika sukses, backend mengirim status beserta atribut user (username, role) sehingga aplikasi mobile mengetahui hak akses pengguna sama seperti di web.
2. **Fetch data**: halaman list/detail melakukan `request.get('http://HOST/<module>/json/')`, mengubah respons ke model Dart, lalu ditampilkan dengan `FutureBuilder`. Karena menggunakan session, endpoint yang memerlukan login (misal modul comparison) otomatis mengenali pengguna.
3. **Kirim data (form)**: ketika user membuat data baru (contoh: menambah catatan comparison), Flutter memanggil `request.postJson('http://HOST/<module>/create-flutter/', jsonEncode({...}))`. View Django menvalidasi data, membuat objek baru, dan mengembalikan `{'status': 'success'}`. Flutter menampilkan SnackBar lalu memicu refresh daftar.
4. **Logout**: `request.logout('http://HOST/auth/logout/')` dipanggil dari menu profil. Django menghapus session, dan aplikasi mobile kembali ke halaman login.

#### 5. Sinkronisasi Hak Akses dan State
1. Setelah login, informasi role (guest/login/admin) diterima dari Django dan disimpan pada state Flutter (misal `UserProvider`). Hal ini memastikan fitur-fitur yang hanya boleh diakses admin di web juga dibatasi di mobile.
2. Setiap operasi tulis/ubah selalu melakukan validasi ganda: validator pada form Flutter dan pemeriksaan `request.user` di view Django, sama seperti pada aplikasi web.
3. Bila data diperbarui di salah satu platform, cukup panggil ulang endpoint JSON agar Flutter menampilkan kondisi terkini; tidak ada mekanisme khusus selain refresh karena sumber data sama.

   
## Initial Dataset Source Credit
<p align="left">
  <a href="https://openf1.org"><img src="https://img.shields.io/badge/Data-OpenF1-red?style=flat-square&logo=fastapi&logoColor=white" alt="OpenF1"/></a>
  <a href="https://en.wikipedia.org/wiki/List_of_Formula_One_circuits"><img src="https://img.shields.io/badge/Data-Wikipedia-blue?style=flat-square&logo=wikipedia&logoColor=white" alt="Wikipedia"/></a>
  <a href="https://www.formula1.com"><img src="https://img.shields.io/badge/Data-formula1-red?style=flat-square&logo=f1&logoColor=white" alt="Formula 1"/></a>
</p>


## Others
<p align="left">
    <a href="https://www.figma.com/files/team/1555462377026209078/project/463049743/SpeedView?fuid=1485588854028450044">
        <img src="https://img.shields.io/badge/Figma-Design%20Mockups-purple?style=for-the-badge&logo=figma&logoColor=white" alt="Figma Project"/>
    </a>
</p>
