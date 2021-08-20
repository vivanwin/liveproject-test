namespace ISBN {
    
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Arithmetic; 
    open Microsoft.Quantum.Arrays; 
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Preparation;
    open Microsoft.Quantum.Diagnostics;


    operation SearchForMissingDigit(inputISBN: Int[], IsbnConstants: (Int, Int), numIterations: Int) : Int {

        let (a, b) = IsbnConstants;

        // Define the oracle
        let phaseOracle = IsbnOracle(IsbnConstants, _);

        // Allocate 4-qubit register necessary to represent the possible values (digits 0-9)
        use digitReg = Qubit[4];
        mutable missingDigit = 0;
        mutable resultISBN = new Int[10];
        mutable attempts = 0;

        // Repeat the algorithm until the result forms a valid ISBN
        repeat{
            RunGroversSearch(digitReg, phaseOracle, numIterations);
            // print the resulting state of the system and then measure
            DumpMachine(); 
            set missingDigit = MeasureInteger(LittleEndian(digitReg));
            set resultISBN = MakeResultIsbn(missingDigit, inputISBN);
            // keep track of the number of attempts
            set attempts = attempts  + 1;
        } 
        until IsIsbnValid(resultISBN);

        // print the results
        Message($"Missing digit: {missingDigit}");
        Message($"Full ISBN: {resultISBN}");
        if attempts == 1 {
            Message($"The missing digit was found in {attempts} attempt.");
        }
        else {
            Message( $"The missing digit was found in {attempts} attempts.");
        }
        return missingDigit;
    }


    operation ComputeIsbnCheck(constants : (Int, Int), digitReg : Qubit[], targetReg : Qubit[]) : Unit is Adj + Ctl {
        let (a, b) = constants;
        ApplyXorInPlace(b, LittleEndian(targetReg));
        MultiplyAndAddByModularInteger(a, 11, LittleEndian(digitReg), LittleEndian(targetReg));
    }


    operation IsbnOracle(constants : (Int, Int), digitReg : Qubit[]) : Unit is Adj + Ctl {
        use (targetReg, flagQubit) = (Qubit[Length(digitReg)], Qubit());
        within {
            X(flagQubit);
            H(flagQubit);
            ComputeIsbnCheck(constants, digitReg, targetReg);
        } apply {
            ApplyControlledOnInt(0, X, targetReg, flagQubit);
        }
    }


    operation PrepareUniformSuperpositionOverDigits(digitReg : Qubit[]) : Unit is Adj + Ctl {
        PrepareArbitraryStateCP(ConstantArray(10, ComplexPolar(1.0, 0.0)), LittleEndian(digitReg));
    }


    operation ReflectAboutUniform(digitReg : Qubit[]) : Unit {
        within {
            Adjoint PrepareUniformSuperpositionOverDigits(digitReg);
            ApplyToEachCA(X, digitReg);
        } apply {
            Controlled Z(Most(digitReg), Tail(digitReg));
        }
    }


    function IsIsbnValid(digits : Int[]) : Bool {
        EqualityFactI(Length(digits), 10, "Expected a 10-digit number.");
        mutable acc = 0;
        for (idx, digit) in Enumerated(digits) {
            set acc += (10 - idx) * digit;
        }
        return acc % 11 == 0;
    }


    function MakeResultIsbn(missingDigit : Int, inputISBN : Int[]) : Int[] {
        mutable resultISBN = new Int[Length(inputISBN)];
        for i in 0..Length(inputISBN) - 1 {
            if inputISBN[i] < 0 {
                set resultISBN w/= i <- missingDigit;
            }
            else {
                set resultISBN w/= i <- inputISBN[i];
            }
        }
        return resultISBN;
    }


    operation RunGroversSearch(register : Qubit[], phaseOracle : ((Qubit[]) => Unit is Adj), iterations : Int) : Unit {
        PrepareUniformSuperpositionOverDigits(register);
        for _ in 1 .. iterations {
            phaseOracle(register);
            ReflectAboutUniform(register);
        }
    }
}
