# Encoding: UTF-8
# ==============================================================================
# ПРОЕКТ 4020-НМ / PECHNIK-ENGINEERING-HUB (v65.9)
# РЕЛИЗ: НАКОПИТЕЛЬНЫЙ КОНВЕЙЕР v50.4 И ЭТАЛОННАЯ СМЕТА v55.2 (БЕЗ МУСОРА)
# ==============================================================================

require 'fileutils'
require 'sketchup'

module PechnikEngineeringHub
  class SceneExporter
    class << self

      # Автоматическое развертывание структуры директорий
      def ensure_project_folders
        base_path = "D:/pechnik-engineering-hub"
        ["#{base_path}/00_my-scripts", "#{base_path}/01_scenes", "#{base_path}/02_specifications"].each do |folder|
          FileUtils.mkdir_p(folder) unless Dir.exist?(folder)
        end
      end

      # ========================================================================
      # ЗАДАЧА 1: НАКОПИТЕЛЬНЫЙ ГРАФИЧЕСКИЙ КОНВЕЙЕР v50.4 (ЭКСПОРТ В PNG)
      # ========================================================================
      def export_scenes_to_png
        ensure_project_folders
        model = Sketchup.active_model
        view = model.active_view
        layers = model.layers
        scenes = model.pages

        puts "🧹 Шаг 1: Очистка старых сцен..."
        scenes.to_a.reverse_each { |scene| scenes.erase(scene) }
        init_scene = scenes.add("00_Базовый_Ракурс")
        scenes.selected_page = init_scene
        
        Sketchup.send_action(10507) # Чертежная 2D ISO-изометрия
        model.options["PageOptions"]["TransitionTime"] = 0.0

        output_dir = "D:/pechnik-engineering-hub/01_scenes/"
        FileUtils.mkdir_p(output_dir) unless Dir.exist?(output_dir)

        options = {
          :width => 2400, :height => 1800, :transparent => true, 
          :antialias => true, :compression => 9, :show_summary => false
        }

        puts "🏗️ ========================================================"
        puts "🚀 СКОРОСТНОЙ КОНВЕЙЕР v50.4: Послойная фиксация кадров"
        puts "============================================================"

        (1..54).each do |current_row|
          # 1. Выставляем видимость тегов в модели
          layers.each do |layer|
            layer_name = layer.name.downcase
            if layer_name =~ /row_(\d+)/
              layer.visible = ($1.to_i <= current_row)
            elsif layer_name.start_with?("finish_")
              layer.visible = (current_row == 54)
            elsif layer_name.start_with?("palette_") || layer_name == "untagged"
              layer.visible = true
            end
          end

          # 2. 🔥 ХУК СБРОСА КЭША: Создаем временную сцену
          temp_page = scenes.add("temp_render")
          temp_page.update(2) # Зашиваем состояние слоев
          scenes.selected_page = temp_page

          # Форсируем аппаратную перерисовку экрана видеокартой
          view.invalidate
          view.refresh
          sleep(0.15) # Пауза для стабилизации текстур

          # 3. Запись кадра на диск D
          options[:filename] = File.join(output_dir, "row_#{sprintf('%02d', current_row)}.png")
          view.write_image(options)

          # 4. Стираем временную сцену, полностью освобождая графический буфер
          scenes.erase(temp_page)
          puts "[#{sprintf('%02d', current_row)}/54] УСПЕХ: Кадр жестко зафиксирован."
        end

        UI.messagebox("🎉 [ИНЖЕНЕРНЫЙ СИНТЕЗ v50.4 ВЫПОЛНЕН УСПЕШНО]\nЭкспортировано порядовок: 54")
      end

      # ========================================================================
      # ЗАДАЧА 2: СИНТЕЗ СМЕТЫ И ВЫВОД ЭТАЛОННОГО ОТЧЕТА v55.2 (КНОПКА 2)
      # ========================================================================
      def export_materials_specification
        ensure_project_folders
        model = Sketchup.active_model
        spec_data = Hash.new(0)
        @total_finish_table_area = 0.0

        # Рекурсивный сметный сканер по эталону v55.2
        scan_spec = ->(instance, current_row = "Вне рядов", transform = Geom::Transformation.new) {
          layer_name = instance.layer.name
          if layer_name =~ /row_(\d{1,2})/ || layer_name =~ /Ряд_(\d{1,2})/
            current_row = sprintf("row_%02d", $1.to_i)
          end

          combined_transform = transform * (instance.respond_to?(:transformation) ? instance.transformation : Geom::Transformation.new)

          if instance.respond_to?(:definition)
            def_name = instance.definition.name
            def_name_down = def_name.downcase
            mat_name = instance.material ? instance.material.name.downcase : ""

            # Расчет площади керамогранита finish_table (Твой точный код v55.2)
            if def_name_down.include?('finish_table') || mat_name.include?('finish_table') || def_name_down.include?('столешниц')
              instance.definition.entities.each do |e|
                if e.is_a?(Sketchup::Face)
                  global_normal = e.normal.transform(combined_transform)
                  if global_normal.z > 0.99
                    mat_arr = combined_transform.to_a
                    p_sx = Math.sqrt(mat_arr[0]**2 + mat_arr[1]**2 + mat_arr[2]**2)
                    p_sy = Math.sqrt(mat_arr[4]**2 + mat_arr[5]**2 + mat_arr[6]**2)
                    @total_finish_table_area += (e.area * p_sx * p_sy) * 0.00064516
                  end
                end
              end
            # Сбор кирпичных кодов с автоопределением немаркированных элементов
            elsif def_name =~ /^(LF|SP|SH8)-\d+-[A-Z0-9]+$/ || def_name_down.include?('кирпич') || def_name_down.include?('palette_brick') || def_name_down.include?('шб')
              if def_name =~ /^(LF|SP|SH8)/
                mat_code = $1
              elsif def_name_down.include?('шб') || def_name_down.include?('шамот')
                mat_code = "SH8"
              elsif def_name_down.include?('лицевой') || mat_name.include?('лицевой') || def_name_down.include?('facade') || mat_name.include?('facade')
                mat_code = "LF"
              else
                mat_code = "SP"
              end

              length_mm = (instance.definition.bounds.width.to_mm).round
              virtual_sku = "#{mat_code}-#{length_mm}-ST"
              spec_data[[current_row, virtual_sku]] += 1
            end
          end

          entities_to_parse = instance.respond_to?(:definition) ? instance.definition.entities : (instance.respond_to?(:entities) ? instance.entities : nil)
          if entities_to_parse
            entities_to_parse.each do |child|
              if child.is_a?(Sketchup::ComponentInstance) || child.is_a?(Sketchup::Group)
                scan_spec.call(child, current_row, combined_transform)
              end
            end
          end
        }

        model.active_entities.each { |e| scan_spec.call(e) if e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group) }

        output_path = "D:/pechnik-engineering-hub/02_specifications/specification_summary.txt"
        totals = Hash.new(0.0)

        File.open(output_path, "w:UTF-8") do |file|
          file.puts "====================================================================================="
          file.puts "                 PRODUCTION SPECIFICATION REPORT (FACTORY STANDARD DE/SE)            "
          file.puts "====================================================================================="
          file.puts sprintf("  %-14s | %-25s | %-15s | %-10s", "PRODUCTION ROW", "FACTORY SKU / ELEMENT ID", "FORMAT TYPE", "QTY (PCS)")
          file.puts "-------------------------------------------------------------------------------------"

          spec_data.keys.sort.each do |key|
            row, sku = key
            count = spec_data[key]
            
            parts = sku.split('-')
            mat_type = parts[0]
            length = parts[1].to_i
            
            limit = (mat_type == "SH8") ? 124 : 120
            type_label = (length > limit) ? "FULL (1.0)" : "HALF (0.5)"
            
            file.puts sprintf("  %-14s | %-25s | %-15s | %-10d", row, sku, type_label, count)
            totals[mat_type] += (length > limit) ? count : (count * 0.5)
          end

          # Расчет печных смесей по практической норме
          total_red = totals["SP"] + totals["LF"]
          total_sh8 = totals["SH8"]
          mix_red_kg = (total_red * 1.1).round(1)
          mix_sh8_kg = (total_sh8 * 0.6).round(1)

          file.puts "\n"
          file.puts "====================================================================================="
          file.puts "                           TOTAL FACTORY MATERIAL SUMMARY                            "
          file.puts "====================================================================================="
          file.puts sprintf("  %-40s : %12s pcs", "LF (Кирпич 1нф лицевой)", totals["LF"].to_i.to_s.gsub('.', ','))
          file.puts sprintf("  %-40s : %12s pcs", "SP (Кирпич 1нф строительный полнотелый)", totals["SP"].to_i.to_s.gsub('.', ','))
          file.puts sprintf("  %-40s : %12s pcs", "SH8 (Кирпич шамотный ШБ-8)", totals["SH8"].to_i.to_s.gsub('.', ','))
          if @total_finish_table_area > 0.0
            file.puts sprintf("  %-40s : %12s m2", "FINISH-TABLE (Керамогранит upper)", sprintf("%.2f", @total_finish_table_area).gsub('.', ','))
          end
          file.puts "-------------------------------------------------------------------------------------"
          file.puts "                           ПРАКТИЧЕСКИЙ РАСХОД СМЕСЕЙ                                "
          file.puts "-------------------------------------------------------------------------------------"
          file.puts sprintf("  %-40s : %12s кг", "Глиняно-песчаная смесь (1,1 кг/шт)", mix_red_kg.to_s.gsub('.', ','))
          file.puts sprintf("  %-40s : %12s кг", "Огнеупорный Мертель (0,6 кг/шт)", mix_sh8_kg.to_s.gsub('.', ','))
          file.puts "====================================================================================="
