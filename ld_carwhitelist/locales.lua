Locales = {
    en = { denied = 'This vehicle is only for %s.', removed = 'You are not allowed to use this vehicle (%s).' },
    nl = { denied = 'Dit voertuig is alleen voor %s.', removed = 'Je mag dit voertuig niet gebruiken (%s).' },
    de = { denied = 'Dieses Fahrzeug ist nur für %s.', removed = 'Du darfst dieses Fahrzeug nicht benutzen (%s).' },
    fr = { denied = 'Ce véhicule est réservé à : %s.', removed = 'Tu n\'as pas le droit d\'utiliser ce véhicule (%s).' },
    es = { denied = 'Este vehículo es solo para %s.', removed = 'No puedes usar este vehículo (%s).' },
    pt = { denied = 'Este veículo é apenas para %s.', removed = 'Você não pode usar este veículo (%s).' },
    pl = { denied = 'Ten pojazd jest tylko dla: %s.', removed = 'Nie możesz używać tego pojazdu (%s).' },
    tr = { denied = 'Bu araç sadece %s için.', removed = 'Bu aracı kullanamazsın (%s).' },
}

--- Message in the configured language (unknown -> English).
function LDCWLText(key, ...)
    local code = tostring(Config.Locale or 'en'):lower()
    local lang = Locales[code] or Locales[code:sub(1, 2)] or Locales.en
    local str = lang[key] or Locales.en[key] or key
    local ok, res = pcall(string.format, str, ...)
    return ok and res or str
end
