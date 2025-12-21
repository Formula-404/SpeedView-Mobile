# SpeedView Mobile

Setiap balapan **Formula 1** bukan sekadar tentang dua puluh mobil yang melaju mengitari lintasan. Balapan merupakan hasil dari interaksi kompleks antara kemampuan pembalap, strategi tim, karakteristik mobil, serta faktor eksternal seperti kondisi cuaca dan waktu pit stop. Detail-detail kecil tersebut sering kali menjadi penentu hasil akhir sebuah balapan.

**SpeedView** dikembangkan untuk membantu memahami kompleksitas tersebut secara lebih mendalam. Aplikasi ini bertujuan mengubah data balapan yang bersifat teknis dan sulit diakses menjadi sebuah **pusat analisis interaktif** yang dapat digunakan oleh penggemar Formula 1, mahasiswa, maupun peneliti.

Melalui SpeedView, pengguna dapat:

* Menjelajahi data balapan berdasarkan *meeting*, *session*, *pembalap*, dan *sirkuit*
* Menganalisis performa melalui waktu putaran, pengaruh cuaca, serta strategi pit stop
* Mempelajari aspek teknis olahraga Formula 1, misalnya data mobil, tim, dan telemetri

---

## Kontributor

<table>
    <tr>
        <td align="center">
            <a href="https://github.com/helvenix">
                <img src="https://avatars.githubusercontent.com/u/109453997?v=4" width="80px;" alt="Helven Marcia"/>
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

---

## Modul

<table>
  <tr>
    <th style="width:180px; text-align:left;">Modul</th>
    <th style="text-align:left;">Deskripsi</th>
    <th style="text-align:left;">Pengembang</th>
  </tr>
  <tr>
    <td><b>User</b></td>
    <td>Autentikasi pengguna, pengelolaan profil, dan pengaturan hak akses</td>
    <td>Haekal</td>
  </tr>
  <tr>
    <td><b>Driver</b></td>
    <td>Data pembalap, termasuk kewarganegaraan dan statistik balapan</td>
    <td>Gilang</td>
  </tr>
  <tr>
    <td><b>Circuit</b></td>
    <td>Informasi sirkuit seperti nama, lokasi, panjang lintasan, jumlah tikungan, dan tata letak</td>
    <td>Putri</td>
  </tr>
  <tr>
    <td><b>Meeting</b></td>
    <td>Representasi akhir pekan Grand Prix, misalnya Monaco Grand Prix 2025</td>
    <td>Naila</td>
  </tr>
  <tr>
    <td><b>Session</b></td>
    <td>Data sesi latihan, kualifikasi, sprint, dan balapan</td>
    <td>Putri</td>
  </tr>
  <tr>
    <td><b>Weather</b></td>
    <td>Kondisi lingkungan seperti suhu lintasan, hujan, angin, dan kelembapan</td>
    <td>Putri</td>
  </tr>
  <tr>
    <td><b>Team</b></td>
    <td>Data konstruktor yang terhubung dengan pembalap dan mobil</td>
    <td>Helven</td>
  </tr>
  <tr>
    <td><b>Car</b></td>
    <td>Spesifikasi teknis mobil, termasuk mesin, sasis, dan musim partisipasi</td>
    <td>Naila</td>
  </tr>
  <tr>
    <td><b>Laps</b></td>
    <td>Data performa per putaran, mencakup waktu, sektor, dan telemetri</td>
    <td>Gilang</td>
  </tr>
  <tr>
    <td><b>Pit</b></td>
    <td>Strategi pit stop, pergantian ban, serta waktu yang hilang</td>
    <td>Gilang</td>
  </tr>
  <tr>
    <td><b>Comparison</b></td>
    <td>Fitur perbandingan statistik antara pembalap, tim, mobil, dan sirkuit</td>
    <td>Helven</td>
  </tr>
</table>

---

## Peran Pengguna

### Pengguna Terdaftar

Pengguna yang telah masuk ke sistem dan memiliki kemampuan untuk:

* Membuat serta menyimpan sesi perbandingan
* Membagikan sesi perbandingan kepada pengguna lain

### Administrator

Pengguna dengan hak akses lanjutan yang dapat:

* Mengedit data tertentu yang bersifat ensiklopedis
* Memoderasi forum, termasuk menghapus konten
* Mengakses fitur manajemen tambahan

---

## Penjelasan Alur Integrasi

### Ringkasan Arsitektur

* **Aplikasi web** menggunakan Django sebagai penyedia layanan data, lengkap dengan modul pengguna, pembalap, mobil, sirkuit, dan lainnya, yang menghasilkan keluaran JSON.
* **Aplikasi mobile** dikembangkan menggunakan Flutter dengan Material 3 serta pengelolaan *state* ringan melalui *Provider*.
* **Integrasi web dan mobile** dilakukan menggunakan `CookieRequest` dari pustaka `pbp_django_auth`, sehingga aplikasi mobile dapat memanfaatkan sesi autentikasi Django secara langsung.

### Alur Integrasi dengan Layanan Web

#### 1. Penyediaan Representasi Data pada Django

Setiap modul yang ditampilkan pada aplikasi mobile menyediakan *endpoint* JSON dengan format yang konsisten, misalnya `/car/json/`, `/meeting/json/`, atau `/car/json/<id>/`. Selain itu, disediakan pula *endpoint* untuk permintaan `POST` guna mendukung pembuatan data dari Flutter. Seluruh kontrol peran pengguna tetap dikelola oleh Django melalui mekanisme sesi.

#### 2. Pemetaan Model ke Flutter

Struktur JSON dari layanan web diturunkan menjadi kelas model pada Flutter. Proses ini mencakup pembuatan *factory constructor* serta fungsi konversi, seperti `carFromJson` dan `carToJson`, yang berfungsi mengubah data JSON menjadi objek Dart dan sebaliknya.

#### 3. Penyiapan Jalur Komunikasi

Aplikasi Flutter menambahkan dependensi `pbp_django_auth`, `http`, dan `provider`. Objek `CookieRequest` disimpan dalam *Provider* sehingga dapat diakses secara konsisten di seluruh halaman.

#### 4. Alur Pertukaran Data

Proses autentikasi, pengambilan data, pengiriman data, hingga keluar dari sistem dilakukan sepenuhnya melalui *endpoint* Django yang sama dengan aplikasi web. Dengan pendekatan ini, aplikasi mobile dan web selalu menggunakan sumber data yang identik.

#### 5. Sinkronisasi Hak Akses

Hak akses pengguna disinkronkan antara backend dan aplikasi mobile. Setiap operasi penulisan data divalidasi baik di sisi Flutter maupun Django, sehingga konsistensi dan keamanan tetap terjaga.

---

## Sumber Dataset Awal

<p align="left">
  <a href="https://openf1.org">
    <img src="https://img.shields.io/badge/Data-OpenF1-red?style=flat-square&logo=fastapi&logoColor=white" alt="OpenF1"/>
  </a>
  <a href="https://en.wikipedia.org/wiki/List_of_Formula_One_circuits">
    <img src="https://img.shields.io/badge/Data-Wikipedia-blue?style=flat-square&logo=wikipedia&logoColor=white" alt="Wikipedia"/>
  </a>
  <a href="https://www.formula1.com">
    <img src="https://img.shields.io/badge/Data-Formula%201-red?style=flat-square&logo=f1&logoColor=white" alt="Formula 1"/>
  </a>
</p>

---

## Desain Antarmuka (Figma)

<p align="left">
  <a href="https://www.figma.com/files/team/1555462377026209078/project/463049743/SpeedView?fuid=1485588854028450044">
    <img src="https://img.shields.io/badge/Figma-Desain%20Antarmuka-purple?style=for-the-badge&logo=figma&logoColor=white" alt="Figma"/>
  </a>
</p>

---

## Aplikasi

Unduh aplikasi versi terbaru melalui tautan berikut:

<p align="left">
  <a href="https://app.bitrise.io/app/01e70d89-e788-4193-b052-607f36aca7e6/installable-artifacts/9b8a234e4528d957/public-install-page/54e593c012ff512998a3511c027f58b1">
    <img src="https://img.shields.io/badge/Android-SpeedView-androidgreen?style=for-the-badge&logo=android&logoColor=white" alt="Android"/>
  </a>
</p>
