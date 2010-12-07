/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package SnakePlayer;
import java.awt.Robot;
import java.awt.Color;
import java.awt.image.BufferedImage;
import java.awt.Toolkit;
import java.awt.Rectangle;
import javax.imageio.ImageIO;
import java.awt.Graphics2D;
import java.awt.event.InputEvent;
import java.awt.event.KeyEvent;


/**
 *
 * @author hornairs
 */
public class Player {

    private Color BLACK = new Color(0,0,0);
    private Color WHITE = new Color(255,255,255);
    private Color PAGE_BACKGROUND_COLOR = WHITE;
    private Color GAME_BORDER_COLOR = BLACK;
    private Color GAME_BACKGROUND_COLOR = new Color(238,238,238);
    
    private int x;
    private int y;
    private int game_x;
    private int game_y; 
    
    public Player() {
    }
    

}
