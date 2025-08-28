# db/seeds.rb

# ============================================================
#  USUARIOS DEL SISTEMA (se preservan; no se borran)
# ============================================================

User.find_or_create_by!(name: 'Jorge Vargas') do |u|
  u.password              = 'Cuicui2004@'
  u.password_confirmation = 'Cuicui2004@'
  u.secret_code           = '1234@@'
  u.role                  = 'superuser'
end

User.find_or_create_by!(name: 'Einar Vargas') do |u|
  u.password              = 'Yampiterparker@'
  u.password_confirmation = 'Yampiterparker@'
  u.secret_code           = '12345@@'
  u.role                  = 'superuser'
end

# Superusuario: Griselle Tellez
User.find_or_create_by!(name: 'Griselle Tellez', role: 'superuser') do |u|
  u.password              = 'Miguelon009@'
  u.password_confirmation = 'Miguelon009@'
  u.secret_code           = '3961'
end


User.find_or_create_by!(name: 'Fernando Tellez') do |u|
  u.password              = 'valenciaga@'
  u.password_confirmation = 'valenciaga@'
  u.secret_code           = ''       # no aplica para normal
  u.role                  = 'normal'
end

User.find_or_create_by!(name: 'juan perez') do |u|
  u.password              = 'valenciaga@@'
  u.password_confirmation = 'valenciaga@@'
  u.secret_code           = '123'    # no aplica para normal
  u.role                  = 'normal'
end

# ============================================================
#  CLIENTE EJEMPLO (se preserva si ya existe)
# ============================================================

Customer.find_or_create_by!(client_number: '1234567') do |c|
  c.name              = 'Yamil Vargas'
  c.enrollment_date   = Date.parse('2025-07-01')
  c.plan              = 'mes'
  c.search_number     = '1234567'
  c.next_payment_date = Date.parse('2025-07-31')

  img = Rails.root.join('app/assets/images/customers/yamil_vargas.jpg')
  if File.exist?(img)
    c.photo.attach(
      io: File.open(img),
      filename: 'yamil_vargas.jpg',
      content_type: 'image/jpeg'
    )
  end
end

# ============================================================
#  PRODUCTOS E-COMMERCE (se preservan; se actualizan si existen)
# ============================================================

PRODUCTS = [
  { name: 'Bariita de costco',      description: '.',    price: 25, stock: 50,  file: 'bariita_de_costco.jpg' },
  { name: 'Protein Bar',            description: '',     price: 15, stock: 30,  file: 'protein_bar.jpg' },
  { name: 'Agua kirdland',          description: '',     price: 20, stock: 100, file: 'agua_kirkland.jpg' },
  { name: 'Scoop proteina whey',    description: '',     price: 20, stock: 40,  file: 'scoop_proteina_whey.jpg' },
  { name: 'Powerade mora',          description: '',     price: 30, stock: 40,  file: 'powerade_mora.jpg' },
  { name: 'Powerade uva',           description: '',     price: 35, stock: 20,  file: 'powerade_uva.jpg' },
  { name: 'Scoop de creatina',      description: '',     price: 30, stock: 50,  file: 'scoop_de_creatina.jpg' },
  { name: 'Agua chica kirkland',    description: '',     price: 8,  stock: 100, file: 'agua_chica_kirkland.jpg' },
  { name: 'Proteína Gold',          description: '',     price: 30, stock: 50,  file: 'proteina_gold.jpg' },
  { name: 'Quemador (CLA +)',       description: '',     price: 15, stock: 50,  file: 'quemador_cla.jpg' },
  { name: 'Pre entreno',            description: '',     price: 20, stock: 50,  file: 'pre_entreno.jpg' },
  { name: 'Aminoácidos',            description: '',     price: 20, stock: 50,  file: 'aminoacidos.jpg' },
  { name: 'Monster blanco',         description: '',     price: 45, stock: 30,  file: 'monster_blanco.jpg' },
  { name: 'Electrolit',             description: '',     price: 30, stock: 100, file: 'electrolit.jpg' }
]

PRODUCTS.each do |attrs|
  prod = Product.find_or_initialize_by(name: attrs[:name])
  prod.update!(
    description: attrs[:description],
    price:       attrs[:price],
    stock:       attrs[:stock]
  )

  img = Rails.root.join('app/assets/images/products', attrs[:file])
  if !prod.image.attached? && File.exist?(img)
    prod.image.attach(
      io: File.open(img),
      filename: attrs[:file],
      content_type: 'image/jpeg'
    )
  end
end

# ============================================================
#  CLASES DE GIMNASIO
# ============================================================

ClassType.find_or_create_by!(name: 'jumping')      { |c| c.price = 50 }
ClassType.find_or_create_by!(name: 'stepgym')      { |c| c.price = 25 }
ClassType.find_or_create_by!(name: 'cardio dance') { |c| c.price = 15 }

# ============================================================
#  IMPORTACIÓN MASIVA DE CLIENTES (archivo tabulado .txt)
# ============================================================
# Coloca tu archivo en:
#   db/seed_data/legacy_customers.txt
# Formato por línea (tabulado):
#   <ID>\t<NOMBRE>\t<MENSUALIDAD|SEMANA|DIA>\t<MM/DD/YYYY>
#
LEGACY_FILE = Rails.root.join('db', 'seed_data', 'legacy_customers.txt')

if File.exist?(LEGACY_FILE)
  puts "Importando clientes desde #{LEGACY_FILE}..."

  plan_map = {
    'MENSUALIDAD' => 'mes',
    'SEMANA'      => 'semana',
    'DIA'         => 'dia'
  }

  created = 0
  updated = 0
  skipped = 0
  line_no = 0

  File.foreach(LEGACY_FILE, chomp: true) do |raw|
    line_no += 1
    line = raw.to_s.strip
    next if line.empty?

    parts = line.split("\t").map(&:strip)
    unless parts.size == 4
      skipped += 1
      puts "[WARN] L#{line_no}: formato inválido — #{raw.inspect}"
      next
    end

    id_str, name_txt, plan_txt, date_str = parts
    client_no = id_str.to_i
    plan_txt  = plan_txt.upcase

    begin
      enrollment = Date.strptime(date_str, '%m/%d/%Y')
    rescue ArgumentError
      enrollment = Date.current
      puts "[WARN] L#{line_no}: fecha inválida '#{date_str}', usando #{enrollment}"
    end

    plan = plan_map[plan_txt] || 'mes'
    next_pay =
      case plan
      when 'dia'    then enrollment + 1
      when 'semana' then enrollment + 7
      else               enrollment + 30
      end

    c = Customer.find_or_initialize_by(client_number: client_no)
    c.name              = name_txt
    c.enrollment_date   = enrollment
    c.plan              = plan
    c.next_payment_date = next_pay
    c.search_number     = client_no.to_s

    if c.save
      if c.previous_changes.key?('id')
        created += 1
      else
        updated += 1
      end
    else
      skipped += 1
      puts "[WARN] L#{line_no}: Cliente ##{client_no} no se guardó (#{c.errors.full_messages.to_sentence})"
    end
  end

  puts ">>> Importación: creados=#{created}, actualizados=#{updated}, omitidos=#{skipped}"
else
  puts "Archivo no encontrado: #{LEGACY_FILE} — omitiendo importación."
end
