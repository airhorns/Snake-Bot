module Snake
  class TestStrategy < Strategy
    def run(player)
      puts player.interactor.get_auto_delay
      puts player.interactor.is_auto_wait_for_idle
      puts player.interactor.to_s

      # result = JRubyProf.profile do
      #   begin
          player.start_game!              
          player.go(:up, 15)
          loop do
            player.go(:right, 7)
            player.go(:down, 7)
            player.go(:left, 7)
            player.go(:up, 7)
          end
        #rescue
        #end
      #end
      #JRubyProf.print_flat_text(result, "flat.txt")
      #JRubyProf.print_graph_text(result, "graph.txt")
      #JRubyProf.print_graph_html(result, "graph.html")
      #JRubyProf.print_call_tree(result, "call_tree.txt")
      #JRubyProf.print_tree_html(result, "call_tree.html")
    end
  end
end
