# coding: utf-8

module LazyHighCharts
  module LayoutHelper
    include ActionView::Helpers::TagHelper

    def high_chart(placeholder, object, &block)
      object.html_options.merge!({:id => placeholder})
      object.options[:chart][:renderTo] = placeholder
      high_graph(placeholder, object, &block).concat(content_tag("div", "", object.html_options))
    end

    def high_stock(placeholder, object, &block)
      object.html_options.merge!({:id => placeholder})
      object.options[:chart][:renderTo] = placeholder
      high_graph_stock(placeholder, object, &block).concat(content_tag("div", "", object.html_options))
    end

    def high_graph(placeholder, object, &block)
      build_html_output("Chart", placeholder, object, &block)
    end

    def high_graph_stock(placeholder, object, &block)
      build_html_output("StockChart", placeholder, object, &block)
    end

    def build_html_output(type, placeholder, object, &block)
      options_collection = [generate_json_from_hash(OptionsKeyFilter.filter(object.options))]
      options_collection << %|"series": [#{generate_json_from_array(object.series_data)}]|

      core_js =<<-EOJS
        var options = { #{options_collection.join(',')} };
        #{capture(&block) if block_given?}
        window.chart_#{placeholder.underscore} = new Highcharts.#{type}(options);
      EOJS

      if defined?(request) && request.respond_to?(:xhr?) && request.xhr?
        graph =<<-EOJS
        <script type="text/javascript">
        (function() {
          #{core_js}
        })()
        </script>
        EOJS
      elsif defined?(Turbolinks) && request.headers["X-XHR-Referer"]
        graph =<<-EOJS
        <script type="text/javascript">
        (function() {
          var f = function(){
            document.removeEventListener('page:load', f, true);
            #{core_js}
          };
          document.addEventListener('page:load', f, true);
        })()
        </script>
        EOJS
      else
        graph =<<-EOJS
        <script type="text/javascript">
        (function() {
          var onload = window.onload;
          window.onload = function(){
            if (typeof onload == "function") onload();
            #{core_js}
          };
        })()
        </script>
        EOJS
      end

      if defined?(raw)
        return raw(graph)
      else
        return graph
      end

    end

    private

    def generate_json_from_hash hash
      hash.to_json
    end
  end
end

ActionView::Base.send :include, LazyHighCharts::LayoutHelper
