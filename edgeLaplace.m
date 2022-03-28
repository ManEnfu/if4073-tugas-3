function J = edgeLaplace(I, tre)
    H = [0 1 0; 1 -4 1; 0 1 0];
    J = uint8(convn(double(I), double(H), "same")) > tre;
end