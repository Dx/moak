//
//  TutorialViewController.swift
//  moak
//
//  Created by Dx on 05/06/17.
//  Copyright © 2017 moak. All rights reserved.
//

import UIKit

class TutorialViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    var requiredScreen = "BarCode"
    
    // MARK: - View methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureScreen()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func clickOk(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Methods
    
    func configureScreen() {
        switch requiredScreen {
        case "BarCode":
            self.titleLabel.text = "Busca por código de barras"
            self.descriptionLabel.text = "Si el producto que quieres agregar tiene código de barras y tienes el producto cerca, ¡esta es la mejor forma de agregar productos! Iré aprendiendo qué productos compras y compararé con este código de barras."
        case "Description":
            self.titleLabel.text = "Busca por descripción de producto"
            self.descriptionLabel.text = "Escribe el nombre del producto que buscas. Te mostraré los productos que encuentre. ¡Prueba la opción de dictado!"
        case "MagicList":
            self.titleLabel.text = "Lista de productos sugeridos"
            self.descriptionLabel.text = "Aquí te muestro los productos que regularmente compras. Elige los que necesitas y se agregarán a tu lista. Así ya no tienes que estar pensando qué te hace falta."
        case "Detail":
            self.titleLabel.text = "Detalle de un producto"
            self.descriptionLabel.text = "Puedes registrar el precio de un producto normal o en promoción 3x2. Si es 3x2 solo puedes poner cantidades como 3, 6, 9. El precio total lo calculo en automático."
        default:
            self.titleLabel.text = "Hola"
            self.descriptionLabel.text = "Cómo estás?"
        }
    }
}
