# TMUX
alias tmxl="tmux ls"
alias tmxa="tmux a -t"
alias tmxk="tmux kill-session -t"

function tmx(){
# Obtiene el nombre de la sesión como primer argumento
    local session_name=$1

    # Crea una nueva sesión de tmux con el nombre especificado
    tmux new-session -d -s $session_name

    # Crea una nueva ventana en la sesión con nombre 'RECON'
    tmux new-window -t $session_name -n 'RECON'

    # Crea una nueva ventana en la sesión con nombre 'CONTENT'
    tmux new-window -t $session_name -n 'CONTENT'

    # Crea una nueva ventana en la sesión con nombre 'EXPLOITS'
    tmux new-window -t $session_name -n 'EXPLOITS'

    # Selecciona la primera ventana de la sesión
    tmux select-window -t $session_name:1
    
    # Elimina la ventana predefinida con índice 0
    tmux kill-window -t $session_name:0 

    # Vincula la terminal actual a la sesión creada
    tmux attach-session -t $session_name
}