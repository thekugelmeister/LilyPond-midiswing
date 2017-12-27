function [ aligned ] = alignbeats( beatpos, original )
if isempty(original)
    aligned = [];
else
    next = original(1);
    rest = original(2:end);
    % if off beat:
    if beatpos ~= 0
        if beatpos + next <= 1/4
            disp 1
            aligned = [next alignbeats(mod(beatpos + next, 1/4), rest)];
        else
            disp 2
            partial = (1/4) - beatpos;
            remaining = next - partial;
            aligned = [partial 0 alignbeats(0, [remaining rest])];
        end
    else
        nextpos = mod(beatpos + next, 1/4);
        if nextpos == 0
            disp 3
            aligned = [next alignbeats(0, rest)];
        else
            if next > 1/4
                disp 4
               aligned = [(next - nextpos) 0 nextpos alignbeats(nextpos, rest)]; 
            else
                disp 5
                aligned = [next alignbeats(nextpos, rest)]; 
            end
        end
    end
end

end

