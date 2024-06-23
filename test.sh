
hosts=()

hosts+=("1")
hosts+=("2")
hosts+=("3")

echo ${hosts[@]}

hosts+=("4" "5")

echo ${hosts[@]}

function foo(){
    local a=("$@")
    echo ${a[@]}
}

foo "${hosts[@]}"

