//
//  ViewController.swift
//  Digital Signature
//
//  Created by Alex Azarov on 28/11/2017.
//  Copyright © 2017 Alex Azarov. All rights reserved.
//

import Cocoa

func dialogError(question: String, text: String) {
    let alert = NSAlert()
    alert.messageText = question
    alert.informativeText = text
    alert.alertStyle = .critical
    alert.addButton(withTitle: "OK")
    alert.runModal()
}

func isPrime(_ number: Int) -> Bool {
    return number > 1 && !(2..<number).contains { number % $0 == 0 }
}

func dialogOK(question: String, text: String) {
    let alert = NSAlert()
    alert.messageText = question
    alert.informativeText = text
    alert.alertStyle = .informational
    alert.addButton(withTitle: "OK")
    alert.runModal()
}

func browseFile() -> String {
    let dialog = NSOpenPanel();
    dialog.title                   = "Choose a file";
    dialog.showsResizeIndicator    = true;
    dialog.showsHiddenFiles        = false;
    dialog.canCreateDirectories    = true;
    dialog.allowsMultipleSelection = false;
    
    if (dialog.runModal() == NSApplication.ModalResponse.OK) {
        let result = dialog.url
        
        if (result != nil) {
            return result!.path
        }
    } else { return "" }
    return ""
}

class ViewController: NSViewController {

    @IBOutlet weak var p_textfield: NSTextField!
    @IBOutlet weak var q_textfield: NSTextField!
    @IBOutlet weak var d_textfield: NSTextField!
    @IBOutlet weak var e_textfield: NSTextField!
    @IBOutlet weak var hash_field: NSTextField!
    @IBOutlet weak var signature_textfield: NSTextField!
    @IBOutlet var msg_textview: NSTextView!
    
    var filePath = ""
    var msg_bytes = [UInt8]()
    var p = 0
    var q = 0
    var d = 0
    var n = 0
    var msg_hash = 0
    var signature = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func inverse(n: Int, modulus: Int) -> Int{
        var a = n, b = modulus
        var x = 0, y = 1, x0 = 1, y0 = 0, q = 0, temp = 0
        while (b != 0) {
            q = a / b
            temp = a % b
            a = b
            b = temp
            temp = x; x = x0 - q * x; x0 = temp;
            temp = y; y = y0 - q * y; y0 = temp;
        }
        if(x0 < 0) { x0 += modulus }
        return x0
    }
    
    // a^z mod n
    func fast_exp(a: Int ,z: Int, n: Int) -> Int {
        var a1 = a
        var z1 = z
        var x = 1
        while (z1 != 0) {
            while ((z1 % 2) == 0) {
                z1 = z1 / 2
                a1 = (a1*a1) % n
            }
            z1 = z1 - 1
            x = (x * a1) % n
        }
        return x
    }
    
     var russianAlphabet = [0xC0, 0xC1, 0xC2, 0xC3, 0xC4, 0xC5, 0xA8, 0xC6, 0xC7, 0xC8, 0xc9, 0xca, 0xcb, 0xcc, 0xcd, 0xce, 0xcf, 0xd0, 0xd1, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda, 0xdb, 0xdc, 0xdd, 0xde, 0xdf]
    //["А", "Б", "В", "Г", "Д", "Е", "Ё", "Ж", "З", "И", "Й", "К", "Л", "М", "Н", "О", "П", "Р", "С", "Т", "У", "Ф", "Х", "Ц", "Ч", "Ш", "Щ", "Ъ", "Ы", "Ь", "Э", "Ю", "Я"]
    
    func indexOfAlphabet(forCharacter character: UInt8) -> Int {
        for index in 0..<russianAlphabet.count {
            if russianAlphabet[index] == character {
                return index + 1
            }
        }
        return -1
    }

    
    func GetHash() -> Int {
        var h = 100
        for index in 0..<msg_bytes.count {
            // h = ((h + indexOfAlphabet(forCharacter: msg_bytes[index])) * (h + indexOfAlphabet(forCharacter: msg_bytes[index]))) % n
            h = (h + Int(msg_bytes[index])) * (h + Int(msg_bytes[index])) % n
            print(h)
        }
        return h
    }
    
    @IBAction func CreateSignature(_ sender: Any) {
//        guard msg_bytes.count > 0 else {
//            dialogError(question: "Error!", text: "Please, open a file.")
//            return
//        }
        guard Int(p_textfield.stringValue) != nil else {
            dialogError(question: "Error!", text: "Please, specify p.")
            return
        }
        p = Int(p_textfield.stringValue)!
        guard isPrime(p) else {
            dialogError(question: "Error!", text: "P is not prime.")
            return
        }
        guard Int(q_textfield.stringValue) != nil else {
            dialogError(question: "Error!", text: "Please, specify q.")
            return
        }
        q = Int(q_textfield.stringValue)!
        guard isPrime(q) else {
            dialogError(question: "Error!", text: "Q is not prime.")
            return
        }
        guard Int(d_textfield.stringValue) != nil else {
            dialogError(question: "Error!", text: "Please, specify d.")
            return
        }
        d = Int(d_textfield.stringValue)!
        
        n = p * q
//        guard n > 255 else {
//            dialogError(question: "Error!", text: "p * q should be greater then 255.")
//            return
//        }
        let euler = (p - 1) * (q - 1)
        
        for index in 2...euler {
            if d % index == 0 && euler % index == 0 {
                dialogError(question: "Error!", text: "D isn't correct!")
                return
            }
        }
        
        let e = inverse(n: d, modulus: euler)
        e_textfield.stringValue = "\(e)"

        msg_hash = GetHash()
        hash_field.stringValue = String(msg_hash)
        signature = fast_exp(a: msg_hash, z: d, n: n)
        signature_textfield.stringValue = "\(signature)"
        try! String(signature).write(to: URL(fileURLWithPath: filePath + ".signature"), atomically: false, encoding: .utf8)
    }
    
    @IBAction func VerifySignature(_ sender: Any) {
        guard signature_textfield.stringValue != "" else {
            dialogError(question: "Error!", text: "Please, specify signature file.")
            return
        }
//        guard msg_bytes.count > 0 else {
//            dialogError(question: "Error!", text: "Please, open a file.")
//            return
//        }
        guard Int(p_textfield.stringValue) != nil else {
            dialogError(question: "Error!", text: "Please, specify p.")
            return
        }
        p = Int(p_textfield.stringValue)!
        guard Int(q_textfield.stringValue) != nil else {
            dialogError(question: "Error!", text: "Please, specify q.")
            return
        }
        q = Int(q_textfield.stringValue)!
        guard Int(e_textfield.stringValue) != nil else {
            dialogError(question: "Error!", text: "Please, specify e.")
            return
        }
        let e = Int(e_textfield.stringValue)!
        
        n = p * q
        let euler = (p - 1) * (q - 1)
        let d = inverse(n: e, modulus: euler)
        d_textfield.stringValue = "\(d)"
        msg_hash = GetHash()
        hash_field.stringValue = String(msg_hash)
        signature = fast_exp(a: msg_hash, z: d, n: n)
        if (signature != Int(signature_textfield.stringValue)) {
            dialogError(question: "Error!", text: "Incorrect digital signature!")
        } else {
            dialogOK(question: "OK!", text: "Digital signature is correct!")
        }
        
    }
    
    @IBAction func OpenSignature(_ sender: Any) {
        filePath = browseFile()
        do {
            signature = (try Int(String(contentsOf: URL(fileURLWithPath: filePath), encoding: .utf8)))!
            signature_textfield.stringValue = "\(signature)"
        }
        catch {
            dialogError(question: "Error!", text: "Cannot open a signature file.")
            return
        }
    }
    
    @IBAction func OpenFile(_ sender: Any) {
        filePath = browseFile()
        if let data = NSData(contentsOfFile: filePath) {
            var buffer = [UInt8](repeating: 0, count: data.length)
            data.getBytes(&buffer, length: data.length)
            msg_textview.string = ""
            for byte in buffer {
                msg_textview.string.append(String(byte) + " ")
            }
            msg_bytes = buffer
        }
    }
}

