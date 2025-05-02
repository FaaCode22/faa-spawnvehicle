-- Konfigurasi
local spawnKey = 167 -- Kode tombol F6 (167 adalah kode untuk tombol F6)
local deleteDelay = 100 -- Delay sebelum kendaraan dihapus (dalam milidetik, 5000 = 5 detik)

-- Daftar kendaraan yang dapat di-spawn
local vehicleList = {
    { label = "bf400", model = "bf400" },
    { label = "bati2", model = "bati2" },
    { label = "zr3803", model = "zr3803" },
}

local spawnedVehicle = nil -- Variabel untuk menyimpan kendaraan yang di-spawn
local isInVehicle = false -- Variabel untuk mengecek apakah pemain sudah berada di dalam kendaraan

-- Fungsi untuk menampilkan menu pilihan kendaraan
local function showVehicleMenu()
    local menuOptions = {}
    for i, vehicle in ipairs(vehicleList) do
        table.insert(menuOptions, {
            header = vehicle.label,
            params = {
                event = "spawn-vehicle:spawn",
                args = { model = vehicle.model }
            }
        })
    end

    -- Tambahkan opsi untuk menutup menu
    table.insert(menuOptions, {
        header = "Tutup Menu",
        params = {
            event = "qb-menu:closeMenu"
        }
    })

    -- Tampilkan menu menggunakan qb-menu
    exports['qb-menu']:openMenu(menuOptions)
end

-- Fungsi untuk men-spawn kendaraan
local function spawnVehicle(model)
    local playerPed = PlayerPedId() -- Mendapatkan ID ped pemain
    local playerCoords = GetEntityCoords(playerPed) -- Mendapatkan koordinat pemain

    -- Cek apakah pemain sudah berada di dalam kendaraan
    if IsPedInAnyVehicle(playerPed, false) then
        TriggerEvent('chat:addMessage', {
            color = { 255, 0, 0},
            multiline = true,
            args = {"System", "Anda sudah berada di dalam kendaraan!"}
        })
        return
    end

    -- Cek apakah pemain berada di dekat jalan
    local isOnRoad, spawnCoords, spawnHeading = GetClosestVehicleNodeWithHeading(playerCoords.x, playerCoords.y, playerCoords.z, 1, 3.0, 0)
    if not isOnRoad then
        TriggerEvent('chat:addMessage', {
            color = { 255, 0, 0},
            multiline = true,
            args = {"System", "Anda harus berada di dekat jalan untuk men-spawn kendaraan!"}
        })
        return
    end

    -- Muat model kendaraan
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end

    -- Spawn kendaraan
    local vehicle = CreateVehicle(model, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnHeading, true, false)
    SetPedIntoVehicle(playerPed, vehicle, -1) -- Masukkan pemain ke dalam kendaraan
    SetVehicleEngineOn(vehicle, true, true, false) -- Nyalakan mesin kendaraan

    -- Simpan kendaraan yang di-spawn
    spawnedVehicle = vehicle
    isInVehicle = true -- Set status pemain berada di dalam kendaraan

    -- Beri notifikasi
    TriggerEvent('chat:addMessage', {
        color = { 0, 255, 0},
        multiline = true,
        args = {"System", "Kendaraan berhasil di-spawn!"}
    })

    -- Mulai thread untuk memantau apakah pemain turun dari kendaraan
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(1000) -- Cek setiap 1 detik
            if not IsPedInVehicle(playerPed, spawnedVehicle, false) then -- Jika pemain tidak berada di dalam kendaraan
                Wait(deleteDelay) -- Tunggu delay sebelum menghapus kendaraan
                if DoesEntityExist(spawnedVehicle) then
                    DeleteVehicle(spawnedVehicle) -- Hapus kendaraan
                    spawnedVehicle = nil -- Reset variabel
                    isInVehicle = false -- Reset status pemain
                    TriggerEvent('chat:addMessage', {
                        color = { 255, 0, 0},
                        multiline = true,
                        args = {"System", "Kendaraan telah dihapus karena Anda meninggalkannya."}
                    })
                end
                break -- Keluar dari thread
            end
        end
    end)
end

-- Event untuk menangani pilihan kendaraan
RegisterNetEvent('spawn-vehicle:spawn')
AddEventHandler('spawn-vehicle:spawn', function(data)
    spawnVehicle(data.model)
end)

-- Bind tombol F6 untuk menampilkan menu pilihan kendaraan
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustReleased(0, spawnKey) then -- Cek jika tombol F6 ditekan
            if not isInVehicle then -- Cek apakah pemain sudah berada di dalam kendaraan
                showVehicleMenu()
            else
                TriggerEvent('chat:addMessage', {
                    color = { 255, 0, 0},
                    multiline = true,
                    args = {"System", "Anda sudah berada di dalam kendaraan!"}
                })
            end
        end
    end
end)