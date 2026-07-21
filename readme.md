# 🧹 Linux Housekeeping Manager

Linux Housekeeping Manager adalah utility berbasis Bash untuk membantu melakukan housekeeping storage pada server Linux secara interaktif.

Tool ini dirancang untuk mempermudah proses cleanup pada beberapa sumber penggunaan storage seperti:

- GitLab Runner build/workspace
- System Logs
- Systemd Journal
- Docker
- Custom Directory
- Saved / Configured Directories

Tool menyediakan mode **Quick Cleanup** untuk cleanup cepat dan **Advanced Cleanup** untuk melakukan preview serta exclude sebelum file dihapus.

---

## ✨ Features

### GitLab Runner Cleanup

Membersihkan workspace/build directory GitLab Runner berdasarkan umur directory.

Berbeda dengan cleanup file biasa, GitLab Runner cleanup dilakukan berdasarkan **umur directory/project**, bukan umur masing-masing file.

Hal ini mencegah kondisi seperti:

- File dependency lama terhapus
- File baru masih tersisa
- Pipeline gagal karena dependency project tidak lengkap

Contoh struktur:

    /home/gitlab-runner/builds/
    └── runner-id/
        ├── project-a/
        ├── project-b/
        └── project-c/

Project yang memenuhi batas umur cleanup akan diproses sebagai satu directory.

---

### System Logs Cleanup

Melakukan housekeeping terhadap system/application logs berdasarkan konfigurasi:

- Umur file
- Ukuran file
- Mode cleanup

---

### Systemd Journal Cleanup

Membantu membersihkan penggunaan storage dari systemd journal.

---

### Docker Housekeeping

Menyediakan housekeeping Docker dengan dukungan:

- Stopped containers
- Dangling / unused images
- Build cache
- Unused networks
- Docker volumes (Advanced Cleanup)
- Docker disk usage preview

Quick Cleanup menampilkan kondisi Docker sebelum dan sesudah cleanup:

    TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
    Images          12        2         13.69GB   12.07GB
    Containers      2         0         32.77kB   32.77kB
    Local Volumes   40        2         3.275GB   3.275GB
    Build Cache     9         0         435.2MB   0B

> Docker volumes tidak dibersihkan secara otomatis pada Quick Cleanup karena dapat berisi persistent application/database data.

---

### Custom Directory

Memungkinkan user memasukkan directory secara manual untuk dilakukan housekeeping.

Contoh:

    /opt/application/cache
    /var/lib/application/tmp
    /data/archive

Tersedia:

- Quick Cleanup
- Advanced Cleanup

---

### Configured Directories

Directory yang sering digunakan dapat disimpan sehingga tidak perlu memasukkan path berulang kali.

Configured directories disimpan dalam configuration file dan dapat digunakan kembali pada cleanup berikutnya.

---

## 🚀 Installation

Clone repository:

    git clone <YOUR-GITHUB-REPOSITORY-URL>

Masuk ke directory project:

    cd <PROJECT-DIRECTORY>

Berikan permission execute:

    chmod +x HK_Folder.sh

Jalankan aplikasi:

    ./HK_Folder.sh

Untuk operasi pada directory yang membutuhkan root permission:

    sudo ./HK_Folder.sh

---

## 📋 Requirements

Minimum requirement:

- Linux
- Bash
- GNU coreutils
- `find`
- `stat`
- `du`
- `df`

Optional:

- Docker — diperlukan untuk fitur Docker Housekeeping
- systemd / journalctl — diperlukan untuk fitur Journal Cleanup
- GitLab Runner — diperlukan jika menggunakan GitLab Runner Cleanup

Cek Bash:

    bash --version

Cek Docker:

    docker --version

Cek journalctl:

    journalctl --version

---

## 🖥️ Main Menu

Setelah aplikasi dijalankan, user akan melihat menu utama.

Contoh:

    =========================================
                 Cleanup Menu
    =========================================

    1. GitLab Runner
    2. System Logs
    3. Journal
    4. Docker
    5. Custom Directory
    6. Configured Directories
    7. Back

Pilih menu dengan memasukkan nomor yang tersedia.

---

## ⚡ Quick Cleanup

Quick Cleanup digunakan untuk melakukan housekeeping tanpa memilih file satu per satu.

Flow:

    Select Cleanup
          ↓
    Scan
          ↓
    Filter Candidate
          ↓
    Preview / Summary
          ↓
    Confirmation
          ↓
    Delete
          ↓
    Summary

Quick Cleanup cocok digunakan untuk housekeeping rutin atau directory yang sudah diketahui aman untuk dibersihkan.

---

## 🔍 Advanced Cleanup

Advanced Cleanup memberikan kontrol lebih sebelum data dihapus.

Flow:

    Select Directory
          ↓
    Scan
          ↓
    Candidate Preview
          ↓
    Select Excluded Files
          ↓
    Build Final Delete List
          ↓
    Confirmation
          ↓
    Delete
          ↓
    Summary

Contoh candidate preview:

    ===============================================================
    Candidate Files
    ===============================================================

    No  Age(days)  Size(MB)  Reason      File
    1   45         120       AGE         /data/cache/file1.tar
    2   60         850       AGE+SIZE    /data/cache/file2.tar
    3   35         210       SIZE        /data/cache/file3.log

User dapat mengecualikan file tertentu sebelum proses cleanup.

Contoh:

    Exclude Files

    Examples:
      2
      2,5
      1,3,8

    Press ENTER to continue without excluding.

Jika user memasukkan:

    1,3

maka candidate nomor 1 dan 3 tidak akan dihapus.

---

## 🦊 GitLab Runner Cleanup

Pilih:

    Cleanup Menu
        ↓
    GitLab Runner

Tool akan mencoba mendeteksi lokasi GitLab Runner build directory.

Contoh:

    Searching GitLab Runner directories...

    [OK] /home/gitlab-runner/builds
    [--] /var/lib/gitlab-runner/builds

Setelah ditemukan, tool akan:

1. Scan project/workspace directory
2. Mengecek umur directory
3. Memilih directory yang memenuhi cleanup policy
4. Menampilkan jumlah candidate
5. Melakukan cleanup setelah confirmation

> GitLab Runner menggunakan directory-based cleanup untuk mencegah penghapusan sebagian dependency project.

---

## 🐳 Docker Housekeeping

Pilih:

    Cleanup Menu
        ↓
    Docker

Docker harus:

- Terinstall
- Docker daemon aktif
- User memiliki permission untuk menjalankan Docker

Tool akan melakukan validasi otomatis.

### Quick Cleanup

Quick Cleanup dapat membersihkan:

- Stopped containers
- Dangling images
- Build cache
- Unused networks

Sebelum cleanup:

    Docker usage before cleanup

    TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
    Images          12        2         13.69GB   12.07GB
    Containers      2         0         32.77kB   32.77kB
    Local Volumes   40        2         3.275GB   3.275GB
    Build Cache     9         0         435.2MB   0B

User akan diminta confirmation:

    Proceed? [Y/n]:

Setelah cleanup, Docker usage akan ditampilkan kembali.

### Advanced Cleanup

Advanced Cleanup memungkinkan cleanup berdasarkan kategori seperti:

- Containers
- Images
- Build Cache
- Networks
- Volumes

> ⚠️ **WARNING:** Docker volumes dapat menyimpan persistent data seperti PostgreSQL, MySQL, Redis, Jenkins, SonarQube, Nexus, dan aplikasi lainnya. Pastikan volume tidak lagi diperlukan sebelum menghapusnya.

---

## 📁 Custom Directory Cleanup

Pilih:

    Cleanup Menu
        ↓
    Custom Directory

Masukkan absolute path:

    /path/to/directory

Contoh:

    /data/cache

Setelah directory tervalidasi, pilih:

    1. Quick Cleanup
    2. Advanced Cleanup
    3. Back

Gunakan **Advanced Cleanup** jika ingin melihat dan mengecualikan file tertentu sebelum delete.

---

## 💾 Configured Directories

Configured Directories digunakan untuk menyimpan directory yang sering di-housekeeping.

Directory tersimpan pada:

    directories.list

Contoh:

    /data/cache
    /opt/application/tmp
    /var/lib/build-cache

Directory tersebut dapat digunakan kembali tanpa memasukkan path secara manual.

---

## ⚙️ Configuration

Configuration utama disimpan dalam config file.

Contoh:

    CONFIG_VERSION=2
    AGE_DAYS=30
    SIZE_MB=100
    MODE=OR

### AGE_DAYS

Menentukan batas umur candidate.

Contoh:

    AGE_DAYS=30

File/directory yang memenuhi batas umur 30 hari dapat menjadi candidate cleanup.

### SIZE_MB

Menentukan threshold ukuran.

Contoh:

    SIZE_MB=100

File berukuran sesuai/melebihi threshold dapat menjadi candidate tergantung mode.

### MODE

Contoh:

    MODE=OR

Candidate memenuhi salah satu kondisi:

    AGE OR SIZE

Jika menggunakan:

    MODE=AND

Candidate harus memenuhi:

    AGE AND SIZE

---

## 📂 Project Structure

Contoh struktur project:

    .
    ├── HK_Folder.sh
    ├── config/
    │   ├── config.conf
    │   └── directories.list
    │
    └── lib/
        ├── menu.sh
        ├── config.sh
        ├── scanner.sh
        ├── cleanup.sh
        ├── cleanup_runner.sh
        └── docker.sh

Struktur aktual dapat berbeda tergantung versi project.

---

## ⚠️ Safety Notes

Tool ini dapat menghapus file dan directory secara permanen.

Sebelum menggunakan pada production server:

1. Review konfigurasi `AGE_DAYS`, `SIZE_MB`, dan `MODE`.
2. Gunakan Advanced Cleanup untuk directory yang sensitif.
3. Periksa candidate sebelum confirmation.
4. Jangan menghapus Docker volumes tanpa mengetahui isi volume tersebut.
5. Pastikan GitLab Runner tidak sedang menggunakan workspace yang akan dibersihkan.
6. Lakukan testing pada non-production environment terlebih dahulu.

Disarankan melakukan backup terhadap data penting sebelum menjalankan housekeeping.

---

## 🔧 Troubleshooting

### Permission Denied

Jalankan menggunakan permission yang sesuai:

    sudo ./HK_Folder.sh

Atau pastikan user memiliki akses terhadap target directory.

### Docker daemon is not running

Cek Docker:

    systemctl status docker

Start Docker:

    sudo systemctl start docker

### Docker Permission Denied

Pastikan user memiliki permission Docker atau jalankan tool menggunakan sudo.

### Directory Not Found

Pastikan menggunakan absolute path:

    /home/user/cache

Bukan:

    ./cache

### GitLab Runner Directory Not Detected

Pastikan GitLab Runner build directory berada pada lokasi yang didukung atau tambahkan lokasi directory yang sesuai melalui konfigurasi/profile.

---

## 🧪 Recommended Testing

Sebelum digunakan di production, buat directory testing:

    mkdir -p /tmp/hk-test

Buat beberapa dummy files:

    touch /tmp/hk-test/test1.log
    touch /tmp/hk-test/test2.log

Untuk mensimulasikan file lama:

    touch -d "60 days ago" /tmp/hk-test/test1.log

Tambahkan file besar jika ingin menguji size threshold:

    dd if=/dev/zero of=/tmp/hk-test/test-large.bin bs=1M count=110

Kemudian jalankan HK Manager terhadap:

    /tmp/hk-test

Gunakan **Advanced Cleanup** terlebih dahulu untuk memastikan candidate detection bekerja sesuai konfigurasi.

---

## 🤝 Contributing

Contribution, bug report, dan feature request dipersilakan.

Workflow:

    git clone <REPOSITORY-URL>

    git checkout -b feature/my-feature

    # Make changes

    git add .

    git commit -m "Add new feature"

    git push origin feature/my-feature

Kemudian buat Pull Request.

---

## 📜 License

Tambahkan license sesuai kebutuhan project.

Contoh:

    MIT License

---

## ⚠️ Disclaimer

Gunakan tool ini dengan hati-hati.

Author tidak bertanggung jawab atas kehilangan data akibat konfigurasi yang salah, pemilihan directory yang salah, atau penghapusan Docker resources yang masih dibutuhkan.