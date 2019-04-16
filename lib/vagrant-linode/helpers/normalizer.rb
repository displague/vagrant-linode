module VagrantPlugins
  module Linode
    module Helpers
      module Normalizer
        def normalize_plan_label(plan_label)
          # if config plan is "Linode x" instead of "Linode xGB", look for "(x/1024)GB instead", when x >= 1024
          plan_label_has_size = plan_label.match(/(\d{4,})$/)
          if plan_label_has_size
            plan_size = plan_label_has_size.captures.first.to_i
            plan_label.sub(/(\d{4,})$/, "#{plan_size / 1024}GB")
          else
            plan_label
          end
        end
      end
    end
  end
end