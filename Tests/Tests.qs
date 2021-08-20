namespace Tests {

    open ISBN;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Measurement;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Math;

    @Test("QuantumSimulator")
    operation AllocateQubit() : Unit {

        use q = Qubit();
        AssertMeasurement([PauliZ], [q], Zero, "Newly allocated qubit must be in |0> state.");

        Message("Test passed.");
    }
    @Test("QuantumSimulator")
    operation CheckOracle() : Unit {

        use inputRegister = Qubit[4];
        use targetRegiter = Qubit[4];

        let a = 7;
        let b = 4;

        for i in 0..9{

            // Encode the interger into the input register
            ApplyPauliFromBitString(PauliX,true,IntAsBoolArray(i,4) ,inputRegister);

            //Apply the quantum oracle
            ComputeIsbnCheck((a,b),inputRegister,targetRegiter);

            //Measure the oracle result
            let result = MultiM(targetRegiter);
            let intResult = ResultArrayAsInt(result);
            
            //Check if the quantum result is the same as the classical implementation
            AllEqualityFactI([calculateOracleClasical(a,b,i)],[intResult],"Results do not match");

            //Reset for next run
            ResetAll(inputRegister);
            ResetAll(targetRegiter);
        }
    }

    //Classical implementation of the quantum oracle
    function calculateOracleClasical(a : Int, b: Int, x: Int ) : Int {
        return ModI(a*x +b,11);
    }
}
