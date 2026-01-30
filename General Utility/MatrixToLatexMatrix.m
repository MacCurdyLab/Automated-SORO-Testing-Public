%% MatrixToLatexMatrix
% 
% Date: 10/12/2025
% Inputs:
%   matrix - matrix, double. Some matlab matrix that the user wants to
%   display in Latex
%
% Output:
%   Latex_String - String that can be copy/pasted into Overleaf/Latex
%   editor to display the matrix made in MATLAB. 
% 

% NOTE: string is in a single line, may need to cut into multiple lines
% in Latex. 

% Does not include Brackets or braces. Copy/paste Latex_String into
% overleaf/editor, as such:

% \begin{bmatrix}, "Latex_String" , \end{bmatrix} 

% \num converts to scientific notation. add \usepackage{siunitx},
% \sisetup{scientific-notation=true} to latex preamble


function Latex_String = MatrixToLatexMatrix(matrix)

sz = size(matrix);

SciNo = "\num{";
% SciNo = "";
SciNo2 = "}";
% SciNo2 = " ";
Latex_String = "";

for row = 1:(sz(1))

    for col = 1:(sz(2))
        
        % if strlength(matrix(row, col)) > 4
        %     matrix(row, col) = extractBefore(matrix(row, col), 5);
        % end            

        if col == sz(2) 
            Latex_String = append(Latex_String, SciNo, num2str(matrix(row, col)), SciNo2);
        else
            Latex_String = append(Latex_String, SciNo, num2str(matrix(row, col)), SciNo2, " & ");
        end

    end

    % Latex_String = Latex_String + " \\ " + newline + "\hline" + newline;
    Latex_String = Latex_String + " \\ " + newline;

end

Latex_String;

end